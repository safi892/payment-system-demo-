# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter (Material 3). Existing scaffold created with `flutter create` targets Android/iOS/desktop/web; Android is the demo target. Stack confirmed by the existing pubspec.yaml and platform folders.

## Users

Primary user: the intern's supervisor and internship reviewers evaluating a payment-gateway integration assignment. End-user persona the app simulates: a Pakistani consumer topping up a digital wallet (PKR) through PayFast Pakistan.

## Product Purpose

A digital wallet recharge system demonstrating the complete payment lifecycle: authentication, wallet balance, recharge via PayFast-style hosted checkout, backend verification, and transaction history. The intern's brief is staged: Phase 1–2 ship a fully polished Flutter app with local mock/simulated payment logic (setState only, service classes); Firebase and a real backend/PayFast integration land in later phases with the UI unchanged.

## Positioning

An internship deliverable that looks and behaves like a production fintech app while the payment layer is swappable: the UI consumes service classes, so the simulated payment flow is replaced by real backend calls without touching screens. Progress is demonstrable every few days.

## Operating Context

Demoed on Android (and desktop/web builds for dev). The recharge flow simulates payment inside the app: amount select → "processing" → success → wallet update → transaction added. Evaluation covers research quality, Flutter implementation, Firebase integration, code quality, security understanding, and documentation. PKR currency. PayFast Pakistan is the reference gateway (sandbox later).

## Capabilities and Constraints

Screens (Phase 1, all with mock data): Splash, Login, Registration, Home, Wallet Dashboard, Recharge, Transaction History, Profile, Settings. State management: setState() only — no state-management packages. Business logic lives in service classes (AuthService, WalletService, PaymentService) so later phases swap implementations only inside services. Recharge presets PKR 500 / 1000 / 5000 + custom amount. Wallet ledger supports recharge and service-charge entries (+/- amounts). Transactions carry ID, amount, type, date, status, payment method.

Undecided (later phases): Firebase project config, backend language choice (FastAPI suggested by brief author), PayFast sandbox credentials.

## Brand Commitments

No name, logo, or visual identity committed by the user. Assignment requires: clean architecture, modular maintainable code, production-style folder structure, comprehensive error handling, well-documented code, and "do not copy code from existing projects — use official documentation and write your own implementation."

## Evidence on Hand

- clean_requirement.md / raw_requirement.md — full internship brief (phases, screens, evaluation weights).
- User's phase plan: Phase 1 mock UI (setState), Phase 2 simulated payment flow, Phase 3 Firebase, Phase 4 backend, Phase 5 replace simulation with PayFast.
- Recommended folder structure (lib/models, services, screens, widgets, utils, constants) is a binding instruction.
- No real users, data, or payment credentials; all demo data is synthetic.

## Product Principles

- The UI must survive the backend swap: screens only talk to service classes.
- Fintech trust comes first: money UI reads precise, statuses are unambiguous, feedback is instant.
- Progress is staged: every phase is demoable on its own.
- Code is the deliverable's argument: documented, modular, production-shaped even when mocked.

## Accessibility & Inclusion

Android Material 3 baseline: touch targets ≥ 48dp, type scales, contrast-aware color roles, edge-to-edge insets, system Back. No product-specific accessibility requirement beyond the platform standard.
