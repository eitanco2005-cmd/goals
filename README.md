# האתגר שלנו · Our Challenge

A habit-challenge app for two people. Each of you logs your own daily goals and can see a summary of your partner's day.

- **Android:** native app (with a home-screen widget later)
- **iPhone:** the same app as an installable web app (PWA)
- **Languages:** Hebrew (default, right-to-left) and English

See [PLAN.md](PLAN.md) for the product plan and milestones.

## Status
- ✅ **Accounts and groups:** sign up, start a challenge or join one with a code, up to 8 people per group
- ✅ **Today:** log the 9 daily goals; see every member's day as ✔/✘ and %, never their exact numbers
- ✅ **Photos:** attach a photo to any goal; members react ❤️ 💪 🔥
- ✅ **Week:** log workouts and junk food for any day of the week; the group sees only met / not met
- ✅ **Board:** heatmap of the whole challenge per member, streaks, goal success rates, and a photo diary for each day
- ✅ **Android home screen:** a widget that rotates through the group's photos from today; long-press shortcuts (+1 glass of water, add a photo)
- ✅ **iPhone:** web app with a guide for adding it to the home screen
- ✅ **Goals:** edit goals for the group, add custom ones, start a new round
- ✅ **Group management:** leave a challenge; replace a shared invite code
- ✅ **Reminders (Android):** end-of-day check that lists what's still open, plus a midday nudge
- ⏭️ **Next:** automatic steps on Android; push notifications between members (nudges, reactions), which need Firebase Cloud Functions

## Run it
```bash
flutter pub get
flutter run -d chrome              # demo mode: in-memory backend with a demo partner
flutter test                       # unit and widget tests
```

**Demo mode** is the default when the app runs without Firebase. Sign up with any email, choose *Join with a code*, and enter **DEMO42** to pair with the demo partner "Noa". Demo data is kept in memory only, so it is lost when the app reloads.

## Android APK without a local Android SDK
Every push runs `.github/workflows/build.yml` on GitHub Actions: analyze, run the tests, build the APK and the web app.
To download the APK, open the repo's **Actions** tab, pick the latest **Build** run, and under **Artifacts** download **android-apk**.

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
