/// Build-time configuration.
library;

/// Build with `--dart-define=USE_FIREBASE=true` once the Firebase project is
/// configured (see docs/FIREBASE_SETUP.md). Without it the app runs in demo
/// mode against an in-memory backend with a demo partner.
const useFirebase = bool.fromEnvironment('USE_FIREBASE');

/// The app's website (Firebase Hosting): the web app, the download page
/// (/download) and invite links (/join/CODE).
const siteUrl = 'https://our-challenge-e8f25.web.app';

/// This build's number (set by CI with --dart-define=APP_BUILD=…; 0 locally).
const appBuild = int.fromEnvironment('APP_BUILD');
