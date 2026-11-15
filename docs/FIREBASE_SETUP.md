# Firebase setup (step by step)

Until you do this, the app runs in **demo mode**: all data is kept in memory on
the device and a demo partner ("Noa", invite code `DEMO42`) is built in. These
steps connect it to a real, free Firebase project so the two of you share
data.

It takes about 20–30 minutes the first time. You only do it once.

---

## 1. Create the Firebase project (free Spark plan)

1. Go to <https://console.firebase.google.com> and sign in with your Google
   account.
2. Click **Create a project** (or **Add project**).
3. Name it, for example `goals-challenge`. Write down the **project ID**
   shown under the name (e.g. `goals-challenge-1a2b3`).
4. Google Analytics: you can turn it **off**. It isn't needed.
5. Click **Create project**. New projects start on the free **Spark** plan, and
   you don't need a credit card.

## 2. Turn on Email/Password sign-in

1. In the left menu, open **Build → Authentication**, then click **Get started**.
2. On the **Sign-in method** tab, choose **Email/Password**.
3. Turn on the first switch (**Email/Password**). Leave "Email link" off.
   Click **Save**.

## 3. Create the Firestore database

1. In the left menu, open **Build → Firestore Database**, then click
   **Create database**.
2. **Location**: choose a region close to Israel. Use **`me-west1` (Tel Aviv)**
   if it's listed, otherwise **`europe-west1` (Belgium)** or
   **`europe-west3` (Frankfurt)**.
   ⚠️ You can't change the location later.
3. Choose **Start in production mode**. The real security rules are deployed
   from this repository in step 6.
4. Click **Create**.

## 4. Install the command-line tools (on your computer)

You need [Node.js](https://nodejs.org) (the LTS version) and Flutter, which is
already installed if you can build the app.

```bash
# Firebase CLI
npm install -g firebase-tools
firebase login                 # opens the browser and signs you in

# FlutterFire CLI (generates the app's Firebase config)
dart pub global activate flutterfire_cli
```

If `flutterfire` is "command not found", add the Dart tools folder to your PATH:

- macOS/Linux: `export PATH="$PATH:$HOME/.pub-cache/bin"` (add it to `~/.zshrc` or `~/.bashrc`)
- Windows: add `%LOCALAPPDATA%\Pub\Cache\bin` to PATH

## 5. Connect the app to the project

Run these commands in the project folder (the one that contains `pubspec.yaml`):

```bash
flutterfire configure --platforms=android,web
```

- Pick the project you created in step 1.
- If it asks for the Android package name, use
  `app.goalschallenge.goals_challenge`.

This command:

- overwrites `lib/firebase_options.dart`. The placeholder in this repo is
  replaced with your project's settings.
- creates `android/app/google-services.json`.
- registers an Android app and a Web app in your Firebase project.

These files only hold public identifiers, not passwords, so committing them
is fine.

Then link the repo's `firebase.json` to your project:

```bash
firebase use --add            # pick the project, alias: default
```

## 6. Deploy the security rules and indexes

```bash
firebase deploy --only firestore
```

This uploads `firestore.rules`, which controls who can read and write what.
Your partner sees only your daily summary, never your exact numbers. It also
uploads `firestore.indexes.json`, the indexes that the Board and Week screens
need. Building the indexes can take a few minutes. Until they're ready, those
screens may show an error.

## 7. Build and publish the web app (for the iPhone)

```bash
flutter build web --release --dart-define=USE_FIREBASE=true
firebase deploy --only hosting
```

The deploy command prints the app's address, e.g.
`https://goals-challenge-1a2b3.web.app`. That's the link for the iPhone.

Run both commands again whenever the app changes.

## 8. Build the Android app (APK)

```bash
flutter build apk --release --dart-define=USE_FIREBASE=true
```

The file is created at `build/app/outputs/flutter-apk/app-release.apk`. To
install it:

1. Copy the APK to the Android phone (e.g. by USB, Google Drive or WhatsApp to yourself).
2. Tap the file to open it. Android asks you to allow installing from this
   source (the Files app, Chrome, etc.). Allow it.
3. Install. For later versions, install the new APK the same way. Your
   data stays in Firebase.

⚠️ **Don't forget `--dart-define=USE_FIREBASE=true`** in both builds. Without it,
the app starts in demo mode.

## 9. Add the web app to the iPhone Home Screen

1. On the iPhone, open the link from step 7 in **Safari**. It must be Safari,
   not Chrome.
2. Tap the **Share** button (the square with an up arrow).
3. Scroll down, tap **Add to Home Screen**, then tap **Add**.
4. From now on, open the app from its Home Screen icon. It opens full-screen
   like a normal app. (iOS 16.4 or newer is needed for notifications later.)

## 10. Start using it

1. Each person creates an account in the app (**Sign up**).
2. One person creates the challenge. The app shows a 6-character invite code.
3. The other person chooses **Join** and types the code (capital or lowercase
   letters both work).

Logging also works offline. Changes sync when the phone reconnects. Creating
and joining a pair needs a connection.

---

### Heads-up for later: notifications (milestone 3)

Scheduled reminders and partner nudges will run on **Cloud Functions**, which
requires upgrading the project to the **Blaze (pay-as-you-go)** plan. Blaze
includes a generous free monthly quota, and two people will stay well within
it, so the expected cost is $0. Google still requires a billing card on file.
You can set a budget alert of, for example, $1 in the Google Cloud console.
You don't need to do this now.

### Troubleshooting

| Symptom | Fix |
|---|---|
| App still shows the demo partner "Noa" | Rebuild with `--dart-define=USE_FIREBASE=true`. |
| App closes or stays blank at start (error mentions `flutterfire configure`) | Step 5 wasn't done, or `lib/firebase_options.dart` was reverted. |
| "Missing or insufficient permissions" | Rules weren't deployed. Run step 6. |
| Board/Week error: "The query requires an index" | Indexes are still building, or weren't deployed (step 6). Wait a few minutes. |
| Web app shows an old version | Close and reopen the app from the Home Screen. Service-worker caching can delay updates by one launch. |

### For developers: testing the security rules

```bash
cd test/firestore_rules
npm install
npm test        # starts the Firestore emulator (needs Java 11+) and runs the tests
```
