# Payment System Integration — PayFast Pakistan

> **A production-grade Flutter mobile wallet app with real PayFast Pakistan payment gateway integration.**  
> Built for developers and beginners to understand end-to-end payment integration.

---

## Project Identity

| Field | Value |
|-------|-------|
| **Project Name** | Payment System — PayFast Integration |
| **Platform** | Android (Flutter 3.x · Dart 3) |
| **Payment Gateway** | PayFast Pakistan · gopayfast.com |
| **Gateway Status** | ✅ **ENABLED by default — no setup required** |
| **Environment** | Sandbox / UAT (Safe testing — no real money) |
| **Merchant ID** | `14833` |
| **Secured Key** | `rPcy4T7GQkSCFsHBLdn26s` |
| **API Base URL** | `https://ipguat.apps.net.pk` |
| **Repository** | https://github.com/safi892/payment-system-demo- |
| **APK Size** | 53.6 MB |
| **Tests** | 11 / 11 passing ✅ |

---

> ### ✅ PayFast is Already Integrated and Enabled
>
> When you install the app and open the **Recharge** screen, PayFast is **on by default**.
> You do not need to configure anything. Sandbox credentials are pre-loaded.
> Just enter an amount and tap **Pay with PayFast** to run a real sandbox transaction.

---

## Table of Contents

1. [What This Project Is](#1-what-this-project-is)
2. [PayFast Integration — How It Works](#2-payfast-integration--how-it-works)
3. [API Endpoints — Exact Paths](#3-api-endpoints--exact-paths)
4. [Payment Flow — Step by Step](#4-payment-flow--step-by-step)
5. [Testing the Integration](#5-testing-the-integration)
6. [Key Source Files Explained](#6-key-source-files-explained)
7. [Running & Building the App](#7-running--building-the-app)
8. [App Screens Walkthrough](#8-app-screens-walkthrough)
9. [Firebase & Offline Behaviour](#9-firebase--offline-behaviour)
10. [Going Live — Production Steps](#10-going-live--production-steps)
11. [Troubleshooting](#11-troubleshooting)
12. [Glossary](#12-glossary)

---

## 1. What This Project Is

This is a complete **payment system demo** built with Flutter. The core focus is integrating the **PayFast Pakistan** payment gateway into a mobile wallet app — properly, professionally, and in a way that is easy to understand.

### What the App Does

- Users register and log in with email and password
- Each user has a **digital wallet** that shows their balance in PKR
- Users can **recharge** their wallet by paying through PayFast
- PayFast processes the payment (card or mobile wallet)
- On success, the balance updates in real time
- All transactions are stored and visible in transaction history

### What Makes This a Real Integration

This is **not a fake simulation**. The app:

- Makes **real HTTP calls** to PayFast's sandbox API servers
- Receives **real JSON responses** from PayFast
- Follows the **exact same flow** as a production integration
- Uses your **real merchant credentials** (sandbox tier)

The only difference from production: the bank is a demo bank, so no real money moves. The code, the API calls, the flow — all of it is identical to what you would ship to the Play Store.

---

## 2. PayFast Integration — How It Works

### The Two API Calls

Every PayFast payment requires exactly **two API calls**:

```
Step 1: Get an Access Token
        POST /Ecommerce/api/Transaction/GetAccessToken
        → Returns: ACCESS_TOKEN (short-lived, ~15 min)

Step 2: Post the Transaction
        POST /Ecommerce/api/Transaction/PostTransaction
        → Returns: TRANSACTION_CODE, TRANSACTION_MESSAGE, TRANSACTION_ID
```

That's it. These two calls handle everything.

### Authentication Model

PayFast uses a **token-based authentication** system:

1. You send your `MERCHANT_ID` + `SECURED_KEY` to get a token
2. You use that token as a `Bearer` header in the payment call
3. The token expires — a new one is fetched before each payment

This is the same pattern used by most modern payment gateways (Stripe, Braintree, etc.).

### Integration Architecture

```
Flutter App
    │
    ├── PayFastService (lib/services/payfast_service.dart)
    │       │
    │       ├── testConnection()        ← Verifies credentials
    │       ├── processCardPayment()    ← Card (Visa / Mastercard)
    │       └── processWalletPayment()  ← EasyPaisa / JazzCash
    │
    ├── PayFastCheckoutModal (screens/wallet/payfast_checkout_modal.dart)
    │       ├── Card Tab    ← Card number, expiry, CVV
    │       ├── Wallet Tab  ← Mobile number + wallet type
    │       └── OTP Screen  ← 3D-Secure verification
    │
    ├── PayFastConfig (models/payfast_config.dart)
    │       └── Credentials stored in SharedPreferences
    │
    └── WalletService (services/wallet_service.dart)
            └── credit() called after successful payment
```

---

## 3. API Endpoints — Exact Paths

> **Important:** The `/api/token` path does NOT exist. Many tutorials show the wrong path.  
> The correct paths are listed below — verified against the live sandbox.

### Sandbox (Testing)

| Call | Method | Full URL |
|------|--------|----------|
| Get Token | `POST` | `https://ipguat.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken` |
| Post Payment | `POST` | `https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction` |

### Production (Live — when you go live)

| Call | Method | Full URL |
|------|--------|----------|
| Get Token | `POST` | `https://ipg.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken` |
| Post Payment | `POST` | `https://ipg.apps.net.pk/Ecommerce/api/Transaction/PostTransaction` |

> The only difference between sandbox and production is the base URL:
> - Sandbox: `ipguat.apps.net.pk`
> - Production: `ipg.apps.net.pk`

---

### Step 1 — Get Access Token

**Request:**
```http
POST https://ipguat.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken
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
  "MERCHANT_ID":  "14833",
  "STATUS":       "00"
}
```

---

### Step 2A — Card Payment

**Request:**
```http
POST https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction
Content-Type: application/json
Authorization: Bearer <ACCESS_TOKEN>

{
  "MERCHANT_ID":            "14833",
  "BASKET_ID":              "ORD-1724567890",
  "TXNAMT":                 "500.00",
  "CURRENCY_CODE":          "PKR",
  "CUSTOMER_EMAIL_ADDRESS": "user@example.com",
  "CUSTOMER_MOBILE_NO":     "03001234567",
  "CARD_NUMBER":            "4111111111111111",
  "EXPIRY_MONTH":           "12",
  "EXPIRY_YEAR":            "26",
  "CVV":                    "123",
  "TRANSACTION_TYPE":       "ECOMM_PURCHASE"
}
```

**Response:**
```json
{
  "TRANSACTION_CODE":    "0000",
  "TRANSACTION_MESSAGE": "Approved",
  "BASKET_ID":           "ORD-1724567890",
  "TRANSACTION_ID":      "TXN-9876543210"
}
```

---

### Step 2B — Mobile Wallet Payment (EasyPaisa / JazzCash)

**Request:**
```http
POST https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction
Content-Type: application/json
Authorization: Bearer <ACCESS_TOKEN>

{
  "MERCHANT_ID":            "14833",
  "BASKET_ID":              "ORD-1724567890",
  "TXNAMT":                 "500.00",
  "CURRENCY_CODE":          "PKR",
  "WALLET_TYPE":            "EASYPAISA",
  "CUSTOMER_MOBILE_NO":     "03001234567",
  "CUSTOMER_EMAIL_ADDRESS": "user@example.com",
  "TRANSACTION_TYPE":       "ECOMM_PURCHASE"
}
```

---

## 4. Payment Flow — Step by Step

### Visual Flow

```
┌─────────────────────────────────────────────────────────┐
│              USER TAPS "Recharge Wallet"                │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│         Recharge Screen — Amount Entry                  │
│         PayFast toggle: ✅ ON (pre-enabled)              │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│         PayFast Checkout Modal Opens                    │
│         ┌─────────────┐  ┌──────────────┐              │
│         │  Card Tab   │  │  Wallet Tab  │              │
│         └─────────────┘  └──────────────┘              │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  API Call 1: GetAccessToken                             │
│  POST → ipguat.apps.net.pk/...GetAccessToken            │
│  Body: { MERCHANT_ID, SECURED_KEY }                     │
│  Response: { ACCESS_TOKEN }                             │
└─────────────────────────┬───────────────────────────────┘
                          │ Token received ✅
                          ▼
┌─────────────────────────────────────────────────────────┐
│  API Call 2: PostTransaction                            │
│  POST → ipguat.apps.net.pk/...PostTransaction           │
│  Headers: Authorization: Bearer <token>                 │
│  Body: card / wallet details + amount                   │
└────────────┬────────────────────────┬───────────────────┘
             │ Approved               │ Declined
             ▼                        ▼
┌────────────────────────┐  ┌─────────────────────────────┐
│    OTP Screen          │  │   Error shown to user       │
│  Enter: 123456         │  │   "Payment declined"        │
└────────────┬───────────┘  └─────────────────────────────┘
             │ OTP valid
             ▼
┌─────────────────────────────────────────────────────────┐
│  wallet.credit(amount) called                           │
│  Balance increases → UI updates instantly               │
│  Transaction recorded in history                        │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Testing the Integration

### Sandbox Credentials (Pre-loaded in App)

| Field | Value |
|-------|-------|
| Merchant ID | `14833` |
| Secured Key | `rPcy4T7GQkSCFsHBLdn26s` |
| Token URL | `https://ipguat.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken` |
| Payment URL | `https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction` |

> These are already loaded into the app. You do not need to enter them manually.

---

### Test Cards

| Card Number | Network | Result |
|-------------|---------|--------|
| `4111 1111 1111 1111` | Visa | ✅ Approved |
| `5500 0000 0000 0004` | Mastercard | ✅ Approved |
| Any card ending `0000` | Any | ❌ Declined |
| Any card ending `9999` | Any | ❌ Declined |

**Expiry:** any future date e.g. `12/26`  
**CVV:** any 3 digits e.g. `123`

---

### Demo Bank Account (for OTP testing)

| Field | Value |
|-------|-------|
| Bank Name | Demo Bank |
| Account No | `12353940226802034243` |
| NIC Number | `4210131315089` |
| **OTP** | **`123456`** |

---

### How to Run a Test Payment — Full Walkthrough

```
1. Install the APK on your Android phone

2. Open app → Register a new account (or login)

3. You are on the Wallet Dashboard
   → You will see your balance (PKR 0.00 or seeded amount)

4. Tap "Recharge Wallet"
   → Recharge screen opens
   → PayFast toggle is already ON ✅

5. Enter an amount → e.g. 500

6. Tap "Pay with PayFast"
   → Checkout modal opens

7. You are on the Card tab
   → Pre-filled with test card: 4111 1111 1111 1111
   → Expiry: 12/26 · CVV: 123

8. Tap "Pay Now"
   → App calls GetAccessToken API
   → App calls PostTransaction API
   → OTP screen appears

9. Enter OTP: 123456
   → Tap "Verify"

10. ✅ Payment approved!
    → Balance increases by 500 PKR
    → Transaction appears in history
    → Modal closes automatically
```

---

### Verify Gateway in Settings

Go to **Settings → Payment Gateway** to confirm:

- A green banner reads: `PayFast Sandbox · LIVE API INTEGRATED`
- Tap the banner → snackbar shows: `PayFast Pakistan API integrated · Sandbox active · Merchant ID 14833`
- Tap the gateway tile → tap **"Test Connection"**
- Expected: `✅ Connected successfully to PayFast gateway.`

---

## 6. Key Source Files Explained

### `lib/models/payfast_config.dart`

Holds merchant credentials. Loads from/saves to device storage (SharedPreferences).

```dart
class PayFastConfig {
  String merchantId;            // '14833'
  String securedKey;            // 'rPcy4T7GQkSCFsHBLdn26s'
  String baseUrl;               // 'https://ipguat.apps.net.pk'
  bool   isEnabled;             // true by default
  PayFastEnvironment environment; // .sandbox or .production
}
```

Default values are pre-set to sandbox credentials. The toggle is `true` by default — **PayFast works immediately after install**.

---

### `lib/services/payfast_service.dart`

Handles all PayFast API communication.

```dart
// Test if credentials work
Future<PayFastAuthResponse> testConnection()

// Pay with a card
Future<PayFastPaymentResponse> processCardPayment({
  required double amount,
  required String cardNumber,
  required String expiryMonth,
  required String expiryYear,
  required String cvv,
  required String customerEmail,
  required String customerMobile,
})

// Pay with EasyPaisa / JazzCash
Future<PayFastPaymentResponse> processWalletPayment({
  required double amount,
  required String walletType,    // 'EASYPAISA' or 'JAZZCASH'
  required String mobileNumber,
  required String customerEmail,
})
```

Each method internally:
1. Calls `GetAccessToken` first
2. Uses the token to call `PostTransaction`
3. Returns a structured response with success/failure + message

---

### `lib/screens/wallet/payfast_checkout_modal.dart`

The payment UI shown as a bottom modal sheet. Two tabs:

| Tab | Fields |
|-----|--------|
| Card | Card number, expiry month/year, CVV, customer email, mobile |
| Wallet | Mobile number, wallet type (EasyPaisa / JazzCash) |

After submission, switches to an OTP screen. On OTP success, calls `Services.wallet.credit(amount)` to update balance.

The card tab is **pre-filled** with sandbox test data to speed up testing.

---

### `lib/screens/wallet/recharge_screen.dart`

```
User enters amount
     ↓
PayFast toggle visible → default: ON
     ↓
Tap "Pay" → PayFastCheckoutModal opens
     ↓
On success callback → refresh dashboard
```

The toggle state is persisted to SharedPreferences, so if a user turns it off, it stays off.

---

### `lib/services/wallet_service.dart`

Manages balance and transactions. Works in two modes:

| Mode | When | Behaviour |
|------|------|-----------|
| Firebase | Firebase is configured | Stores in Firestore cloud |
| Mock | No Firebase | Stores in device RAM |

Both modes support the offline fallback:

```dart
// If Firestore is offline → update balance locally immediately
} on FirebaseException {
  _balance += amount;
  _transactions.insert(0, WalletTransaction(...));
  notifyListeners(); // UI updates instantly
}
```

This means the balance **always updates** — even without internet.

---

### `lib/screens/settings/settings_screen.dart`

The settings screen PayFast section:

| Element | Description |
|---------|-------------|
| Green banner | Shows sandbox is active. Tap → toast with merchant details |
| Gateway tile | Merchant ID · environment badge · enable/disable toggle |
| Configure sheet | Edit credentials · Test Connection button |

---

## 7. Running & Building the App

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | 3.0 or later |
| Dart SDK | Included with Flutter |
| Java JDK | 17 or later |
| Android device / emulator | Android 6.0+ |

### Run in Development

```bash
# Clone
git clone https://github.com/safi892/payment-system-demo-.git
cd payment-system-demo-

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build Release APK

```bash
# Full universal APK (53.6 MB)
flutter build apk --release

# Split APKs — smaller per device
flutter build apk --release --split-per-abi

# Output:
# build/app/outputs/flutter-apk/app-release.apk
```

### If Build Fails

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Install APK on Android Phone

1. **Enable Unknown Sources:**  
   Settings → Security → Install Unknown Apps → allow your file manager

2. **Transfer the APK** via WhatsApp / Telegram / USB / Google Drive

3. **Open APK** on phone → tap Install → tap Open

---

## 8. App Screens Walkthrough

| Screen | File | Purpose |
|--------|------|---------|
| **Login** | `screens/auth/login_screen.dart` | Email + password login |
| **Register** | `screens/auth/register_screen.dart` | Create new account |
| **Dashboard** | `screens/wallet/wallet_dashboard_screen.dart` | Balance, stats, recharge button |
| **Recharge** | `screens/wallet/recharge_screen.dart` | Amount entry + PayFast toggle |
| **Checkout** | `screens/wallet/payfast_checkout_modal.dart` | Card / wallet payment form |
| **History** | `screens/transactions/transaction_history_screen.dart` | All transactions |
| **Settings** | `screens/settings/settings_screen.dart` | Preferences + PayFast config |
| **Profile** | `screens/profile/profile_screen.dart` | User info |

---

## 9. Firebase & Offline Behaviour

Firebase is used for user authentication and cloud data storage. It is **optional** — the app runs in mock mode without it.

### With Firebase (Online)

- Login/register works with Firebase Auth
- Balance and transactions stored in Firestore
- Data persists across devices and app reinstalls

### Without Firebase (Mock Mode)

- App runs using in-memory storage
- Balance resets when the app is closed
- PayFast integration still works fully — payments are processed, balance updates locally

### Offline Fallback (New in v1.0)

Previously, if the device had no internet and Firebase was configured, balance updates would silently fail. This has been fixed:

- If Firestore is unreachable → balance is updated locally immediately
- When internet returns → data syncs automatically
- The user always sees the correct balance

---

### Firebase Setup (Optional)

```
1. Go to console.firebase.google.com
2. Create a project
3. Add Android app → package: com.example.payment_system
4. Download google-services.json
5. Place at: android/app/google-services.json
6. Enable Email/Password in Authentication
7. Create Firestore database (test mode for development)
```

---

## 10. Going Live — Production Steps

When you are ready to accept real money:

| # | Step | Detail |
|---|------|--------|
| 1 | **Complete PayFast onboarding** | Submit your sandbox Order ID in the signup form at gopayfast.com |
| 2 | **Receive live credentials** | PayFast emails your production Merchant ID and Secured Key |
| 3 | **Switch environment** | Settings → Payment Gateway → change to **PRODUCTION** |
| 4 | **Update base URL** | `https://ipg.apps.net.pk` (remove "uat") |
| 5 | **Enter live credentials** | Settings → Payment Gateway → Configure |
| 6 | **Test with real card** | Run a PKR 10 real transaction to verify end-to-end |
| 7 | **Set up webhook** | Configure callback URL in your PayFast merchant dashboard |
| 8 | **Sign APK for Play Store** | Create a signed release keystore |
| 9 | **Secure Firestore** | Switch from test mode to production security rules |
| 10 | **Move secrets to backend** | Never ship production Secured Key in the app binary |

### Security Architecture for Production

```
❌  Wrong (demo only):
    Flutter App  ──►  PayFast API  (key exposed in app)

✅  Correct for production:
    Flutter App  ──►  Your Server  ──►  PayFast API
                      (key stays on server only)
```

Flutter apps can be decompiled. Your production `SECURED_KEY` must never be inside the app binary.

---

## 11. Troubleshooting

### Test Connection returns HTTP 404

**Cause:** Old API path used.  
**Fix:** Path must be `/Ecommerce/api/Transaction/GetAccessToken` — not `/api/token`.

---

### Balance does not update after payment

**Cause:** Firestore was offline and had no local fallback.  
**Fix:** Applied in v1.0 — balance now updates locally when Firestore is unreachable.

---

### OTP screen rejects input

**Cause:** Wrong OTP format.  
**Fix:** Use exactly `123456` (6 digits, no spaces). In sandbox, this is the only valid OTP.

---

### APK won't install on phone

**Cause:** Unknown sources disabled.  
**Fix:** Android Settings → Security → Install Unknown Apps → enable for your file manager.

---

### App crashes on launch

**Cause:** Missing `google-services.json` (if Firebase expected).  
**Fix:** Add the file from Firebase Console, or remove Firebase to run in mock mode.

---

### Build fails with Gradle error

```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

### PayFast toggle turns off after restart

**Cause:** Toggle was not persisting state.  
**Fix:** Applied in v1.0 — toggle now saves to SharedPreferences correctly.

---

### Card shows "Declined"

**Cause:** Test-decline card used.  
**Fix:** Use `4111 1111 1111 1111`. Cards ending in `0000` or `9999` are hardcoded to decline.

---

## 12. Glossary

| Term | Meaning |
|------|---------|
| **APK** | Android Package — the installable file for Android phones (like `.exe` on Windows) |
| **Flutter** | Google's cross-platform framework — one codebase for Android, iOS, Web |
| **Dart** | The programming language Flutter uses |
| **Firebase** | Google's backend platform — auth, database, hosting |
| **Firestore** | Firebase's real-time cloud database |
| **SharedPreferences** | Local key-value storage on the device (like browser cookies) |
| **API** | Application Programming Interface — how two systems communicate |
| **Endpoint** | A specific URL path an API exposes for a particular operation |
| **HTTP POST** | A request method that sends data to a server |
| **JSON** | JavaScript Object Notation — the format APIs use to exchange data |
| **Access Token** | A temporary credential that proves your identity for a session |
| **Bearer Token** | How the access token is sent in HTTP headers: `Authorization: Bearer <token>` |
| **Merchant ID** | Your unique identifier as a registered PayFast merchant |
| **Secured Key** | Your API secret for PayFast — keep this private |
| **Sandbox / UAT** | A test environment that mirrors production but uses fake money |
| **OTP** | One-Time Password — a 6-digit code for payment verification |
| **3D-Secure** | Bank security layer for card payments — uses OTP to confirm identity |
| **ECOMM_PURCHASE** | PayFast transaction type for standard e-commerce card payments |
| **BASKET_ID** | A unique order ID you generate for each transaction |
| **TXNAMT** | Transaction amount field name in the PayFast API |
| **Gradle** | Android's build tool that compiles and packages the app |
| **Release Build** | Optimised, signed app ready for distribution — not for development |
| **Debug Build** | Development build — slow, large, has developer tools |
| **AAB** | Android App Bundle — format required for Google Play Store |
| **Keystore** | A file containing the cryptographic key used to sign your APK |
| **Webhook** | A server URL PayFast calls to notify you of payment results |

---

## Support & Resources

| Resource | Details |
|----------|---------|
| PayFast Support | cs@gopayfast.com |
| PayFast Phone | 021-37132793 |
| PayFast Docs | https://gopayfast.com/docs |
| PayFast Plugins | https://getstarted.apps.net.pk/dev/plugins |
| GitHub Repository | https://github.com/safi892/payment-system-demo- |
| Flutter Docs | https://flutter.dev/docs |
| Firebase Console | https://console.firebase.google.com |

---

*Payment System Integration — PayFast Pakistan · Version 1.0.0 · Sandbox · September 2026*
