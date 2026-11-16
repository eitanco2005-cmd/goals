/// Build-time configuration.
library;

/// Build with `--dart-define=USE_FIREBASE=true` once the Firebase project is
/// configured (see docs/FIREBASE_SETUP.md). Without it the app runs in demo
/// mode against an in-memory backend with a demo partner.
const useFirebase = bool.fromEnvironment('USE_FIREBASE');
