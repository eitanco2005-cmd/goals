# האתגר שלנו · Our Challenge

A habit-challenge app for two people. Each of you logs your own daily goals and can see a summary of your partner's day.

- **Android:** native app (with a home-screen widget later)
- **iPhone:** the same app as an installable web app (PWA)
- **Languages:** Hebrew (default, right-to-left) and English

See [PLAN.md](PLAN.md) for the product plan and milestones.

## Status
Step 1 is done: sign up and sign in, pairing with an invite code, the Today screen with live sync, and settings in Hebrew and English.
Next: the week view, the year board, editable goals and challenge rounds.

## Run it
```bash
flutter pub get
flutter run -d chrome              # demo mode: in-memory backend with a demo partner
flutter test                       # unit and widget tests
```

**Demo mode** is the default when the app runs without Firebase. Sign up with any email, choose *Join with a code*, and enter **DEMO42** to pair with the demo partner "Noa". Demo data is kept in memory only, so it is lost when the app reloads.

## Real (Firebase) mode
Follow [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md), then:
```bash
flutter build web --dart-define=USE_FIREBASE=true   # iPhone (PWA)
flutter build apk --dart-define=USE_FIREBASE=true   # Android
```

## Project layout
```
lib/
  core/        providers (Riverpod), router (go_router), theme, dates, errors
  domain/      models, default goals, scoring (pure Dart, unit-tested)
  data/        repository contracts + memory (demo/tests) and Firebase implementations
  features/    auth, pairing, today, week, board, settings, shell
  l10n/        app_en.arb / app_he.arb
firestore.rules            security rules: partners see only each other's summaries, never the detailed logs
test/                      unit, widget, and Firestore rules tests (test/firestore_rules, emulator)
```
