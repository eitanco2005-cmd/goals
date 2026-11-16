// Firebase configuration for the project `our-challenge-e8f25`.
//
// These values identify the project; they are not secrets (they ship inside
// every copy of the app). Access is protected by firestore.rules.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'Firebase is configured for Android and the web only.',
      ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBg9AUbTGiLOZVHUYLSf3y6vZByXKQWToE',
    appId: '1:874664490937:web:ccd19c207b4352d3832868',
    messagingSenderId: '874664490937',
    projectId: 'our-challenge-e8f25',
    authDomain: 'our-challenge-e8f25.firebaseapp.com',
    storageBucket: 'our-challenge-e8f25.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB5GWiur-SctVFuWf6ZmVBRTVrm0Umuqvc',
    appId: '1:874664490937:android:1a663d1b5cb14a48832868',
    messagingSenderId: '874664490937',
    projectId: 'our-challenge-e8f25',
    storageBucket: 'our-challenge-e8f25.firebasestorage.app',
  );
}
