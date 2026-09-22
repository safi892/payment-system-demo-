# Digital Wallet Recharge System

A Flutter digital wallet with simulated PayFast Pakistan payments — built for an
internship assignment. Runs on Android with a night-flight instrument-panel UI;
phases 1–2 complete (UI + simulated payments), Firebase integration designed and
ready to wire.

## Status

| Phase | Status |
|---|---|
| 1 — Flutter UI (all screens) | ✅ Complete |
| 2 — Wallet logic + simulated payments | ✅ Complete |
| 3 — Firebase (Auth + Firestore) | 🟡 Code ready — needs `google-services.json` |
| 4 — FastAPI backend | 📝 Designed (`docs/production_architecture.md`) |
| 5 — PayFast sandbox integration | 📝 Designed |

## Quick start

```bash
flutter pub get
flutter analyze          # 0 issues
flutter test             # 8 tests pass
flutter run              # or: flutter build apk --debug
```

No accounts required — the prototype simulates payments and persists the session
locally. Full setup (incl. Firebase wiring) in [`docs/setup_guide.md`](docs/setup_guide.md).

Simulated gateway: any whole amount succeeds · `9999` = declined · `8888` = timeout.

## Features

- Splash, login, registration, wallet dashboard, recharge, transaction history, profile, settings
- Simulated PayFast lifecycle: create → confirm → verify (success / decline / timeout)
- SharedPreferences session persistence
- Demo account: `ali@demo.com` / `demo1234` (seeds PKR 8,900)
- Amount validation: whole PKR, 1–1,000,000
- 8 passing widget/unit tests, clean `flutter analyze`

## Architecture

- `lib/` — Flutter app: `screens/`, `services/`, `models/`, `widgets/`, `utils/`
- Services are swappable — Phase 5 swaps `PaymentService` internals only; UI unchanged
- `docs/production_architecture.md` — layered architecture, API design, sequence diagrams
- `docs/firebase_architecture.md` — schema, data flows, rules rationale, offline/realtime
- `docs/research.md` — gateway comparison + PayFast API study
- `docs/security.md` — threat model and controls
- `docs/test_report.md` — test results and Phase 3+ plan
- `firebase/` — Firestore rules + composite indexes (deploy with `firebase deploy`)

## Design world

Night-flight instrument panel — radar blue, phosphor green, amber accents, mono
typography. Direction contract documented at the top of `lib/main.dart`.

## Deliverables index

| Deliverable | Where |
|---|---|
| Plan | [`PLAN.md`](PLAN.md) |
| Research | [`docs/research.md`](docs/research.md) |
| Architecture + diagrams | [`docs/production_architecture.md`](docs/production_architecture.md) |
| Firebase schema & rules rationale | [`docs/firebase_architecture.md`](docs/firebase_architecture.md) |
| Firestore rules / indexes | [`firebase/firestore.rules`](firebase/firestore.rules) · [`firebase/firestore.indexes.json`](firebase/firestore.indexes.json) |
| Setup & deployment | [`docs/setup_guide.md`](docs/setup_guide.md) |
| Firebase wiring (step-by-step) | [`docs/firebase_wiring_guide.md`](docs/firebase_wiring_guide.md) |
| Test report | [`docs/test_report.md`](docs/test_report.md) |
| Security | [`docs/security.md`](docs/security.md) |
| Demo script / presentation | `docs/demo_script.md` · `docs/presentation_outline.md` |
