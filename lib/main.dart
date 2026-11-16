import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'data/firebase/firebase_setup.dart';
import 'data/memory/memory_backend.dart';
import 'features/widget/widget_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final overrides = useFirebase ? await firebaseOverrides() : demoOverrides();
  unawaited(scheduleWidgetRefresh());
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
