# Payment System — Developer & Beginner Release Guide

> **PayFast Pakistan (Sandbox) · Flutter · Firebase · Android**  
> Version `1.0.0` · Build: Release APK · September 2026

---

## Quick Reference

| Field | Value |
|-------|-------|
| Repository | https://github.com/safi892/payment-system-demo- |
| Platform | Android (Flutter 3.x · Dart 3) |
| Payment Gateway | PayFast Pakistan — gopayfast.com |
| Environment | **Sandbox / UAT** — No real money |
| Merchant ID | `14833` |
| Secured Key | `rPcy4T7GQkSCFsHBLdn26s` |
| Sandbox Base URL | `https://ipguat.apps.net.pk` |
| APK Location | `build/app/outputs/flutter-apk/app-release.apk` |
| APK Size | 53.6 MB |

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [How the App Works — Full Flow](#2-how-the-app-works--full-flow)
3. [PayFast Pakistan Integration — Deep Dive](#3-payfast-pakistan-integration--deep-dive)
4. [Key Files — Code Walkthrough](#4-key-files--code-walkthrough)
5. [Sandbox Testing Guide](#5-sandbox-testing-guide)
6. [Build Instructions](#6-build-instructions)
7. [Firebase Configuration](#7-firebase-configuration)
8. [Common Issues & Fixes](#8-common-issues--fixes)
9. [Going Live — Production Checklist](#9-going-live--production-checklist)
10. [Glossary — Terms for Beginners](#10-glossary--terms-for-beginners)

---

## 1. Project Overview

This is a **Flutter-based digital wallet and payment demo app**. Users can:

- Register / login with email and password
- View their wallet balance and transaction history
- Recharge their wallet using **PayFast Pakistan** (real payment gateway)
- Manage app settings and payment gateway configuration

The app runs in **sandbox mode** — meaning the PayFast API is real, but no actual money moves. It uses demo bank credentials provided by PayFast for testing.

### Key Technologies

| Technology | Purpose |
|------------|---------|
| **Flutter** | UI framework — one codebase runs on Android and iOS |
| **Dart** | Programming language used by Flutter |
| **Firebase Auth** | Email/password login and registration |
| **Firestore** | Cloud database — stores balances and transactions online |
| **PayFast PK** | Real payment gateway — gopayfast.com |
| **SharedPreferences** | Local storage on device — saves PayFast credentials |
| **http package** | Makes HTTP API calls to PayFast servers |
| **crypto package** | Cryptographic signing (HMAC-SHA256) |

### Folder Structure

```
payment_system/
  lib/
    models/          ← Data classes (PayFastConfig, WalletTransaction…)
    services/        ← Business logic (WalletService, PayFastService…)
    screens/
      auth/          ← Login & Register screens
      wallet/        ← Dashboard, Recharge, PayFast Checkout Modal
      settings/      ← App settings + PayFast gateway config
      transactions/  ← Transaction history screen
    widgets/         ← Reusable UI components (buttons, cards, tiles)
    constants/       ← Colors, strings, route names
  test/              ← Unit and widget tests (11 passing)
  android/           ← Android native project files
  backend/           ← Optional Python FastAPI backend (reference only)
  build/
    app/outputs/flutter-apk/   ← Built APK goes here
  RELEASE_NOTES.md   ← This file
```

---

## 2. How the App Works — Full Flow

### User Journey

| Step | Action |
|------|--------|
| **Launch** | App shows Splash screen → checks if user is already logged in |
| **Auth** | Not logged in → Login screen → Enter email + password |
| **Dashboard** | Shows wallet balance, recent transactions, Recharge button |
| **Recharge** | User enters amount → chooses PayFast or Simulation mode |
| **Checkout** | PayFast modal opens with Card tab or Wallet tab |
| **Card Pay** | Enter card details → gateway processes → OTP screen shown |
| **OTP** | Enter OTP sent by bank → payment verified |
| **Success** | Balance increases in real time, transaction appears in history |

### Payment Flow Diagram

```
User presses "Recharge Wallet"
         │
         ▼
  Is PayFast enabled?
    YES ──────────────────────────────────► NO
     │                                      │
     ▼                                      ▼
Open PayFastCheckoutModal           Simulation dialog
     │                                      │
     ▼                                      ▼
POST GetAccessToken API             wallet.credit(amount)
(get ACCESS_TOKEN)                         │
     │                                      ▼
     ▼                               Balance updated ✅
Got token?
  YES ─────────────────────► POST PostTransaction API
  NO  ─────────────────────► Simulation fallback
                                    │
                                    ▼
                            Response: Approved?
                              YES ─► OTP Screen
                              NO  ─► Error message shown
                                    │
                                 OTP valid?
                              YES ─► wallet.credit(amount)
                              NO  ─► "Invalid OTP" error
                                    │
                                    ▼
                             Balance updated ✅
                            Transaction recorded ✅
```

### Wallet Balance — How It Updates

The wallet service has **two modes**:

- **Firebase Mode** *(when Firebase is configured)* — balance stored in Firestore cloud. Works online. If offline, falls back to local update automatically.
- **Mock Mode** *(no Firebase configured)* — balance stored in device RAM only. Resets when app closes. Good for pure demos.

> ⚠️ **Note:** In Sandbox mode, PayFast does not move real money. The balance increase is simulated inside the app after a successful sandbox API response.

---

## 3. PayFast Pakistan Integration — Deep Dive

### What is PayFast Pakistan?

PayFast (gopayfast.com) is a Pakistani payment gateway by **APPS (Avanza Premier Payment Services)**. It lets merchants accept:
- Debit/Credit card payments (Visa, Mastercard)
- Mobile wallet payments (EasyPaisa, JazzCash, UPaisa, etc.)

### 3.1 API Endpoints

| Endpoint | URL |
|----------|-----|
| **Get Token** | `POST https://ipguat.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken` |
| **Post Payment** | `POST https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction` |
| **Sandbox Base** | `https://ipguat.apps.net.pk` |
| **Production Base** | `https://ipg.apps.net.pk` *(live payments only)* |

> ❌ **Common mistake:** The old endpoint `/api/token` returns HTTP 404. The correct path is `/Ecommerce/api/Transaction/GetAccessToken`.

---

### 3.2 Step 1 — Get Access Token

Before every payment, get a short-lived token that proves your merchant identity.

**Request:**
```http
POST /Ecommerce/api/Transaction/GetAccessToken
Content-Type: application/json

{
  "MERCHANT_ID": "14833",
  "SECURED_KEY": "rPcy4T7GQkSCFsHBLdn26s"
}
```

**Response:**
```json
{
  "ACCESS_TOKEN": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "MERCHANT_ID": "14833",
  "STATUS": "00"
}
```

**Dart code** (`lib/services/payfast_service.dart`):
```dart
final tokenUri = Uri.parse(
  '$baseUrl/Ecommerce/api/Transaction/GetAccessToken'
);
final response = await http.post(
  tokenUri,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'MERCHANT_ID': merchantId,
    'SECURED_KEY': securedKey,
  }),
).timeout(Duration(seconds: 10));

final data = jsonDecode(response.body);
final token = data['ACCESS_TOKEN']; // Use this in the payment call
```

---

### 3.3 Step 2 — Post the Transaction (Card Payment)

**Request:**
```http
POST /Ecommerce/api/Transaction/PostTransaction
Content-Type: application/json
Authorization: Bearer <ACCESS_TOKEN>

{
  "MERCHANT_ID":           "14833",
  "BASKET_ID":             "ORD-1234567890",
  "TXNAMT":                "500.00",
  "CURRENCY_CODE":         "PKR",
  "CUSTOMER_EMAIL_ADDRESS":"test@example.com",
  "CUSTOMER_MOBILE_NO":    "03001234567",
  "CARD_NUMBER":           "4111111111111111",
  "EXPIRY_MONTH":          "12",
  "EXPIRY_YEAR":           "26",
  "CVV":                   "123",
  "TRANSACTION_TYPE":      "ECOMM_PURCHASE"
}
```

**Response:**
```json
{
  "TRANSACTION_CODE":    "0000",
  "TRANSACTION_MESSAGE": "Approved",
  "BASKET_ID":           "ORD-1234567890",
  "TRANSACTION_ID":      "TXN-9876543210"
}
```

---

### 3.4 Step 3 — Wallet Payment (EasyPaisa / JazzCash)

```http
POST /Ecommerce/api/Transaction/PostTransaction
Content-Type: application/json
Authorization: Bearer <ACCESS_TOKEN>

{
  "MERCHANT_ID":           "14833",
  "BASKET_ID":             "ORD-1234567890",
  "TXNAMT":                "500.00",
  "CURRENCY_CODE":         "PKR",
  "WALLET_TYPE":           "EASYPAISA",
  "CUSTOMER_MOBILE_NO":    "03001234567",
  "CUSTOMER_EMAIL_ADDRESS":"test@example.com",
  "TRANSACTION_TYPE":      "ECOMM_PURCHASE"
}
```

---

### 3.5 Step 4 — OTP Verification (3D-Secure)

After the card payment is submitted, the bank sends a One-Time Password (OTP) to the cardholder's phone number. The user enters it in the app.

- **In Sandbox:** OTP is always `123456`
- **In Production:** Real OTP is sent via SMS by the bank

---

### 3.6 Simulation Fallback

If the real PayFast API is unreachable (no internet, server down), the app automatically falls back to a **local simulation** so demos still work.

| Scenario | Result |
|----------|--------|
| Card ending `0000` or `9999` | Always **DECLINED** |
| Any other card number | **APPROVED** |
| OTP `9999` or `000000` | **INVALID** |
| OTP `123456` | **VALID** — sandbox success |

---

## 4. Key Files — Code Walkthrough

### 4.1 `lib/models/payfast_config.dart`

Stores merchant credentials. Loads/saves from SharedPreferences (local device storage).

```dart
class PayFastConfig {
  String merchantId;   // '14833'
  String securedKey;   // 'rPcy4T7GQkSCFsHBLdn26s'
  String baseUrl;      // 'https://ipguat.apps.net.pk'
  bool   isEnabled;    // toggle PayFast on/off
  PayFastEnvironment environment; // .sandbox or .production

  // Load saved config (or use defaults)
  static Future<PayFastConfig> load() async { ... }

  // Save to device storage
  Future<void> save() async { ... }
}
```

**Default values** (pre-filled so no manual setup needed):
```dart
static PayFastConfig defaults() => PayFastConfig(
  merchantId:  '14833',
  securedKey:  'rPcy4T7GQkSCFsHBLdn26s',
  baseUrl:     'https://ipguat.apps.net.pk',
  isEnabled:   true,
  environment: PayFastEnvironment.sandbox,
);
```

---

### 4.2 `lib/services/payfast_service.dart`

Main service that talks to PayFast API.

| Method | What it does |
|--------|-------------|
| `testConnection()` | Calls `GetAccessToken` to verify credentials |
| `processCardPayment()` | Gets token → posts card payment |
| `processWalletPayment()` | Gets token → posts wallet payment |
| `verifyOtp()` | Validates OTP (sandbox: any 6-digit code except `9999`/`000000`) |

---

### 4.3 `lib/screens/wallet/payfast_checkout_modal.dart`

The checkout UI shown during payment. Two tabs:

- **Card Tab** — Card number, expiry, CVV. Pre-filled with sandbox test card.
- **Wallet Tab** — Mobile number + wallet type (EasyPaisa / JazzCash).

After submission → OTP screen → on success → calls `wallet.credit()`.

---

### 4.4 `lib/screens/wallet/recharge_screen.dart`

The recharge screen with a PayFast toggle:

- **Toggle ON** → opens `PayFastCheckoutModal`
- **Toggle OFF** → runs simulation dialog

The toggle state persists to SharedPreferences (fixed in this version).

---

### 4.5 `lib/services/wallet_service.dart`

Manages wallet balance and transaction history.

| Method | What it does |
|--------|-------------|
| `credit(amount)` | Adds money. Works offline with local fallback. |
| `debit(amount)` | Deducts money. Works offline with local fallback. |
| `balance` | Current balance in PKR (double) |
| `transactions` | List of all transactions |
| `refresh()` | Pull fresh data from Firestore |

**Offline Fallback (critical fix in this version):**

Previously, if Firestore was offline, balance updates silently failed. Now:

```dart
} on FirebaseException {
  // Firestore offline — credit locally so balance reflects immediately.
  _balance += amount;
  _transactions.insert(
    0,
    WalletTransaction(
      id: transactionId,
      amount: amount,
      type: TransactionType.recharge,
      status: TransactionStatus.completed,
      method: method,
      createdAt: DateTime.now(),
    ),
  );
  if (!_disposed) notifyListeners(); // UI updates instantly
}
```

---

### 4.6 `lib/screens/settings/settings_screen.dart`

Settings screen PayFast section includes:

- **Sandbox Active Banner** — Green bar. Tap to see toast with merchant ID and API status.
- **Gateway Tile** — Merchant ID, environment badge (SANDBOX/PRODUCTION), enable toggle.
- **Configure Sheet** — Update credentials + "Test Connection" button.

---

### 4.7 `lib/services/service_locator.dart`

Single place where all services are created. Acts as a dependency injection container.

```dart
class Services {
  static final wallet  = WalletService();
  static final auth    = AuthService();
  static final payfast = PayFastService();  // ← Added for PayFast
}
```

---

## 5. Sandbox Testing Guide

> Sandbox = safe test environment. No real money involved.

### 5.1 Your Merchant Credentials (Sandbox)

| Field | Value |
|-------|-------|
| Merchant ID | `14833` |
| Secured Key | `rPcy4T7GQkSCFsHBLdn26s` |
| Environment | Sandbox (UAT) |
| Token URL | `https://ipguat.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken` |
| Payment URL | `https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction` |

### 5.2 Demo Bank Details

Use these when the payment flow asks for bank info:

| Field | Value |
|-------|-------|
| Bank Name | Demo Bank |
| Account No | `12353940226802034243` |
| NIC Number | `4210131315089` |
| **OTP** | **`123456`** |

### 5.3 Test Card Numbers

| Card Number | Result |
|-------------|--------|
| `4111 1111 1111 1111` | ✅ VISA — Always APPROVED |
| `5500 0000 0000 0004` | ✅ Mastercard — Always APPROVED |
| `XXXX XXXX XXXX 0000` | ❌ Any card ending `0000` — DECLINED |
| `XXXX XXXX XXXX 9999` | ❌ Any card ending `9999` — DECLINED |
| Expiry | Any future date, e.g. `12/26` |
| CVV | Any 3 digits, e.g. `123` |

### 5.4 How to Run a Test Transaction — Step by Step

1. Install the APK on your Android phone
2. Open app → Login (or Register if new)
3. Dashboard → tap **"Recharge Wallet"**
4. Enter amount (e.g. `500`) → verify PayFast toggle is **ON**
5. Tap **"PAY WITH PAYFAST"** → Checkout modal opens
6. Card tab is pre-filled with test card → tap **"Pay Now"**
7. OTP screen appears → enter `123456` → tap **Verify**
8. ✅ Payment approved! Balance increases by 500 PKR
9. Settings → Payment Gateway → tap green banner to confirm sandbox is active

### 5.5 Test Connection (Settings)

**Settings → Payment Gateway → tap the gateway tile → "Test Connection"**

The app calls the PayFast token endpoint and shows:
- ✅ `Connected successfully to PayFast gateway.` — API reachable, credentials valid
- ❌ Error message — check internet or credentials

---

## 6. Build Instructions

### 6.1 Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | 3.0+ | https://flutter.dev/docs/get-started/install |
| Dart SDK | Included with Flutter | — |
| Android Studio | Latest | For emulator/signing |
| Java JDK | 17+ | For Gradle / Android build |
| Git | Any | To clone the repo |

### 6.2 Clone and Setup

```bash
# 1. Clone the repo
git clone https://github.com/safi892/payment-system-demo-.git
cd payment-system-demo-

# 2. Install Flutter dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run
```

### 6.3 Build Release APK

A release APK is optimised for distribution — smaller, faster, no debug overhead.

```bash
# Build release APK (takes 3–5 minutes first time)
flutter build apk --release

# Output:
# build/app/outputs/flutter-apk/app-release.apk  (53.6 MB)

# Build split APKs (smaller per device architecture)
flutter build apk --release --split-per-abi
# Output:
#   app-arm64-v8a-release.apk    ← most modern phones
#   app-armeabi-v7a-release.apk  ← older phones
#   app-x86_64-release.apk       ← emulators
```

### 6.4 Build App Bundle (for Google Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

> Use AAB for Google Play. Use APK for direct sharing (WhatsApp, email, USB).

### 6.5 Install APK on Android Phone

1. Enable **"Install from Unknown Sources"**  
   → Android Settings → Security → Install Unknown Apps → Allow from Files / WhatsApp
2. Transfer APK to phone (WhatsApp, Telegram, USB cable, Google Drive, email)
3. Open the APK file on the phone → tap **Install**
4. Open the app and test

### 6.6 Debug vs Release — Difference

| | Debug | Release |
|-|-------|---------|
| Speed | Slow | ✅ Fast |
| File size | Large (100+ MB) | ✅ Small (53 MB) |
| Debug overlays | Visible | Hidden |
| Needs USB | Yes (to run) | No |
| For sharing | ❌ No | ✅ Yes |

### 6.7 If Build Fails

```bash
# Clean everything and retry
flutter clean
flutter pub get
flutter build apk --release
```

---

## 7. Firebase Configuration

Firebase handles user **login/registration** and online **wallet data storage**.

### 7.1 What Firebase Does

| Service | Purpose |
|---------|---------|
| Firebase Auth | Email/password login and registration |
| Firestore DB | Stores wallet balances and transaction history online |
| Offline fallback | If Firestore unreachable → balance updates locally *(new in this version)* |

### 7.2 google-services.json

This file connects your Flutter app to your Firebase project.

**Path:** `android/app/google-services.json`

> ⚠️ This file is NOT in the public GitHub repo (for security). Each developer needs their own.

**To set up Firebase for your own project:**

```
1. Go to https://console.firebase.google.com
2. Create a new project (or use existing)
3. Add Android app → enter package name:
   com.example.payment_system
4. Download google-services.json
5. Place it at: android/app/google-services.json
6. In Firebase console → Authentication → Enable Email/Password
7. In Firebase console → Firestore → Create database (Test mode for dev)
```

### 7.3 Without Firebase (Mock Mode)

If Firebase is not configured, the app runs in **mock mode**:
- All data is stored in device RAM only
- Balance resets when the app is closed
- All features still work (PayFast integration, UI, etc.)
- Good for quick demos without cloud setup

---

## 8. Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| **HTTP 404 on Test Connection** | Wrong API endpoint path | Fixed: endpoint is now `/Ecommerce/api/Transaction/GetAccessToken` |
| **Balance not updating after payment** | Firestore offline, no fallback | Fixed: balance now updates locally when Firestore is unreachable |
| **OTP screen rejects `123456`** | Typo or wrong format | Use exactly `123456` (6 digits, no spaces) |
| **APK won't install** | Unknown sources disabled | Settings → Security → Enable "Install Unknown Apps" |
| **App crashes on launch** | Missing `google-services.json` | Add Firebase config or run in mock mode |
| **PayFast toggle not saving** | Bug in onTap handler | Fixed: toggle now persists to SharedPreferences |
| **Build fails: Gradle error** | Cached build state | Run `flutter clean && flutter pub get && flutter build apk --release` |
| **Card declined in sandbox** | Using test-decline card | Use `4111 1111 1111 1111`. Cards ending `0000`/`9999` are always declined by design. |
| **Test Connection shows HTML error** | Wrong endpoint was used | Fixed: endpoint updated to correct PayFast Pakistan path |
| **Balance not decreasing** | `debit()` had no offline fallback | Fixed: debit now works offline just like credit |

---

## 9. Going Live — Production Checklist

When you are ready to accept **real payments**, follow these steps:

| Step | Action |
|------|--------|
| **1. Complete PayFast signup** | Submit your test transaction Order ID at gopayfast.com |
| **2. Get production credentials** | PayFast will email live Merchant ID and Secured Key |
| **3. Update environment in app** | Settings → Payment Gateway → Switch to **PRODUCTION** |
| **4. Update base URL** | Change to `https://ipg.apps.net.pk` (remove "uat") |
| **5. Enter live credentials** | Settings → Payment Gateway → Configure → update fields |
| **6. Test with real card** | Process a small real transaction (PKR 10) to verify end-to-end |
| **7. Set up webhook** | Configure callback URL in PayFast merchant dashboard |
| **8. Sign APK with keystore** | Create a release keystore for Google Play submission |
| **9. Tighten Firestore rules** | Disable test mode, enable production security rules |
| **10. Move secrets to backend** | Never ship Secured Key in the app — use a backend server |

### ⚠️ Security Warning

**Never put your production Secured Key inside the Flutter app code.**  
Flutter apps can be decompiled and the key can be stolen.

**Safe production architecture:**

```
Flutter App  ──►  Your Backend Server  ──►  PayFast API
                  (Secured Key lives here only)
```

```
Unsafe (sandbox demo only):
Flutter App  ──►  PayFast API
(key exposed in app code ← dangerous in production)
```

---

## 10. Glossary — Terms for Beginners

| Term | Meaning |
|------|---------|
| **APK** | Android Package — the file you install on Android phones (like `.exe` on Windows) |
| **Flutter** | Google's framework for building apps from one codebase (Android + iOS + Web) |
| **Dart** | The programming language Flutter uses |
| **Firebase** | Google's backend platform — provides auth, database, hosting |
| **Firestore** | Firebase's cloud NoSQL database — stores data online in real time |
| **SDK** | Software Development Kit — tools and libraries for building apps |
| **API** | Application Programming Interface — a way for apps to talk to each other |
| **Endpoint** | A specific URL you send requests to — like knocking on a specific door |
| **JSON** | JavaScript Object Notation — the data format APIs use (`{"key": "value"}`) |
| **Token / Access Token** | A temporary password that proves who you are (expires after a short time) |
| **Sandbox** | A fake test environment — no real money, safe to experiment |
| **UAT** | User Acceptance Testing — the sandbox stage before going live |
| **OTP** | One-Time Password — a 6-digit code sent to your phone for verification |
| **3D-Secure** | Extra security layer for card payments — bank sends OTP to cardholder |
| **Merchant ID** | Your unique ID as a PayFast merchant (like a shop registration number) |
| **Secured Key** | Your secret API password for PayFast (keep this private!) |
| **HMAC-SHA256** | A method to cryptographically sign requests so they can't be tampered with |
| **SharedPreferences** | Local storage on Android/iOS — like cookies in a browser |
| **Gradle** | The build tool Android uses to compile and package apps |
| **Hot Reload** | Flutter feature that applies UI changes instantly during development |
| **Release Build** | Optimised, production-ready app — smaller, faster, no debug tools |
| **Debug Build** | Development version — slower, larger, has debug overlays |
| **AAB** | Android App Bundle — the format Google Play Store uses |
| **Firestore Rules** | Security rules that control who can read/write what data in Firestore |
| **Dependency** | A library your project uses (listed in `pubspec.yaml`) |
| **pub get** | Flutter command to download all dependencies |

---

## Support & Links

| Resource | Link |
|----------|------|
| PayFast Support | cs@gopayfast.com · 021-37132793 |
| PayFast Docs | https://gopayfast.com/docs |
| PayFast Plugins | https://getstarted.apps.net.pk/dev/plugins |
| GitHub Repo | https://github.com/safi892/payment-system-demo- |
| Flutter Docs | https://flutter.dev/docs |
| Firebase Console | https://console.firebase.google.com |

---

*Document version 1.0.0 — Sandbox use only — September 2026*
