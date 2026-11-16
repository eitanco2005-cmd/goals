import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/providers.dart';
import 'data/firebase/firebase_setup.dart';
import 'data/memory/memory_backend.dart';

/// Build with `--dart-define=USE_FIREBASE=true` once the Firebase project is
/// configured (see README). Without it the app runs in demo mode against an
/// in-memory backend with a demo partner.
const useFirebase = bool.fromEnvironment('USE_FIREBASE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final overrides = useFirebase ? await firebaseOverrides() : demoOverrides();
  runApp(ProviderScope(overrides: overrides, child: const GoalsApp()));
}

List<Override> demoOverrides() {
  final backend = MemoryBackend(seedDemo: true);
  return [
    isDemoModeProvider.overrideWithValue(true),
    authRepositoryProvider.overrideWithValue(backend),
    profileRepositoryProvider.overrideWithValue(backend),
    pairRepositoryProvider.overrideWithValue(backend),
    challengeRepositoryProvider.overrideWithValue(backend),
    logRepositoryProvider.overrideWithValue(backend),
    photoRepositoryProvider.overrideWithValue(backend),
  ];
}
