import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:goals_challenge/firebase_options.dart';

import '../../core/providers.dart';
import 'firebase_backend.dart';

/// Firestore's on-disk cache budget. Bounded so that photos (up to ~1 MB
/// each with their full image) are garbage-collected instead of piling up
/// on the device forever; least recently used documents not needed by an
/// active listener are evicted first.
const firestoreCacheSizeBytes = 150 * 1024 * 1024;

/// Initializes Firebase (with Firestore offline persistence on Android and
/// web) and returns the backend. Shared by the app and the background job
/// that refreshes the home-screen widget.
Future<FirebaseBackend> initFirebaseBackend() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  // Must be set before the first Firestore call.
  firestore.settings = Settings(
    // Offline storage on Android. Not on the web: iOS Safari's IndexedDB
    // (used by the installed iPhone web app) can stall Firestore's live
    // updates, which matters more than offline use there.
    persistenceEnabled: !kIsWeb,
    cacheSizeBytes: firestoreCacheSizeBytes,
  );

  return FirebaseBackend(auth: FirebaseAuth.instance, firestore: firestore);
}

/// Provider overrides that plug [FirebaseBackend] into all repository
/// providers. Called from `main()` when the app is built with
/// `--dart-define=USE_FIREBASE=true`.
Future<List<Override>> firebaseOverrides() async {
  final backend = await initFirebaseBackend();
  return [
    isDemoModeProvider.overrideWithValue(false),
    authRepositoryProvider.overrideWithValue(backend),
    profileRepositoryProvider.overrideWithValue(backend),
    pairRepositoryProvider.overrideWithValue(backend),
    challengeRepositoryProvider.overrideWithValue(backend),
    logRepositoryProvider.overrideWithValue(backend),
    photoRepositoryProvider.overrideWithValue(backend),
  ];
}
