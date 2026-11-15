import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:goals_challenge/firebase_options.dart';

import '../../core/providers.dart';
import 'firebase_backend.dart';

/// Initializes Firebase (with Firestore offline persistence on Android and
/// web) and returns the provider overrides that plug [FirebaseBackend] into
/// all repository providers. Called from `main()` when the app is built with
/// `--dart-define=USE_FIREBASE=true`.
Future<List<Override>> firebaseOverrides() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  // Must be set before the first Firestore call.
  firestore.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    // Keep the cache usable when the web app is open in several tabs.
    webPersistentTabManager: kIsWeb ? WebPersistentMultipleTabManager() : null,
  );

  final backend = FirebaseBackend(
    auth: FirebaseAuth.instance,
    firestore: firestore,
  );
  return [
    isDemoModeProvider.overrideWithValue(false),
    authRepositoryProvider.overrideWithValue(backend),
    profileRepositoryProvider.overrideWithValue(backend),
    pairRepositoryProvider.overrideWithValue(backend),
    challengeRepositoryProvider.overrideWithValue(backend),
    logRepositoryProvider.overrideWithValue(backend),
  ];
}
