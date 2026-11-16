import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/features/auth/sign_in_screen.dart';
import 'package:goals_challenge/features/home_access/home_access_ui.dart';
import 'package:goals_challenge/features/home_access/quick_actions.dart';
import 'package:goals_challenge/features/photos/photo_capture.dart';
import 'package:goals_challenge/features/photos/photo_processing.dart';
import 'package:goals_challenge/features/photos/photo_providers.dart';
import 'package:goals_challenge/features/settings/settings_screen.dart';
import 'package:goals_challenge/features/widget/widget_snapshot.dart';
import 'package:goals_challenge/features/widget/widget_sync.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class FakeShortcuts implements LauncherShortcuts {
  void Function(String type)? onAction;
  List<ShortcutItem> items = const [];

  @override
  Future<void> initialize(void Function(String type) onAction) async =>
      this.onAction = onAction;

  @override
  Future<void> setItems(List<ShortcutItem> items) async => this.items = items;
}

class PinStore implements WidgetStore {
  PinStore({required this.canPin});
  final bool canPin;
  var pinRequests = 0;

  @override
  Future<String?> photoPath(String id) async => null;
  @override
  Future<String> savePhoto(String id, Uint8List jpeg) async => '/w/$id.jpg';
  @override
  Future<void> prune(Set<String> keep) async {}
  @override
  Future<void> publish(WidgetSnapshot snapshot) async {}
  @override
  Future<bool> requestPin() async {
    pinRequests++;
    return canPin;
  }
}

Future<void> pump(
  WidgetTester tester,
  MemoryBackend b, {
  FakeShortcuts? shortcuts,
  WidgetStore? store,
  bool inBrowser = false,
  bool ios = false,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...memoryOverrides(b, widgetStore: store, shortcuts: shortcuts),
        runningInBrowserTabProvider.overrideWithValue(inBrowser),
        isIosBrowserProvider.overrideWithValue(ios),
        photoPickerProvider.overrideWithValue(_NoPicker()),
        photoProcessorProvider.overrideWithValue(
          (bytes) async => processPhoto(bytes),
        ),
      ],
      child: const GoalsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _NoPicker implements PhotoPicker {
  @override
  Future<Uint8List?> pick(PhotoSource source, PhotoTarget target) async => null;
  @override
  Future<LostPhoto?> retrieveLost() async => null;
}

Future<num?> water(MemoryBackend b, {String? uid}) async =>
    (await b
            .watchDailyLog(
              pairId: 'demo-pair',
              uid: uid ?? b.currentUser!.uid,
              date: todayKey(),
            )
            .first)
        .valueOf(GoalIds.water);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('launcher shortcuts', () {
    testWidgets('are registered with titles in the app language', (
      tester,
    ) async {
      final shortcuts = FakeShortcuts();
      await pump(tester, await signedInPairedBackend(), shortcuts: shortcuts);
      expect(shortcuts.items.map((i) => i.localizedTitle), [
        '+1 glass of water',
        'Add a photo',
      ]);
      expect(shortcuts.items.map((i) => i.type), ['log_water', 'add_photo']);
    });

    testWidgets('"+1 glass of water" logs water and confirms', (tester) async {
      final b = await signedInPairedBackend();
      final shortcuts = FakeShortcuts();
      await pump(tester, b, shortcuts: shortcuts);

      shortcuts.onAction!('log_water');
      await tester.pumpAndSettle();
      expect(await water(b), 1);
      expect(find.text('💧 1/8 – logged'), findsOneWidget);

      shortcuts.onAction!('log_water');
      await tester.pumpAndSettle();
      expect(await water(b), 2);
    });

    testWidgets('a shortcut from another tab goes to Today and runs once', (
      tester,
    ) async {
      final b = await signedInPairedBackend();
      final shortcuts = FakeShortcuts();
      await pump(tester, b, shortcuts: shortcuts);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      shortcuts.onAction!('log_water');
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(await water(b), 1);
      await tester.pumpAndSettle();
      expect(await water(b), 1, reason: 'ran exactly once');
    });

    testWidgets('"Add a photo" asks which goal the photo is for', (
      tester,
    ) async {
      final shortcuts = FakeShortcuts();
      await pump(tester, await signedInPairedBackend(), shortcuts: shortcuts);
      shortcuts.onAction!('add_photo');
      await tester.pumpAndSettle();
      expect(find.text('Photo for which goal?'), findsOneWidget);

      await tester.tap(find.text('Vegetables with every meal'));
      await tester.pumpAndSettle();
      // Next comes the usual camera / gallery choice for that goal.
      expect(find.text('Choose from gallery'), findsOneWidget);
    });

    testWidgets('a shortcut tapped while signed out waits for sign-in', (
      tester,
    ) async {
      final b = await signedInPairedBackend();
      final me = b.currentUser!.uid;
      await b.signOut();
      final shortcuts = FakeShortcuts();
      await pump(tester, b, shortcuts: shortcuts);
      shortcuts.onAction!('log_water');
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(
        await water(b, uid: me),
        isNull,
        reason: 'nothing logged while signed out',
      );

      await b.signIn(email: 'me@x.com', password: 'secret1');
      await tester.pumpAndSettle();
      expect(await water(b), 1);
    });
  });

  group('widget pinning (Android)', () {
    testWidgets('Settings pins the widget in one tap', (tester) async {
      final store = PinStore(canPin: true);
      await pump(tester, await signedInPairedBackend(), store: store);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await scrollToCenter(tester, find.text('Add the widget'));
      await tester.tap(find.text('Add the widget'));
      await tester.pumpAndSettle();
      expect(store.pinRequests, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('launchers that cannot pin get manual steps', (tester) async {
      final store = PinStore(canPin: false);
      await pump(tester, await signedInPairedBackend(), store: store);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await scrollToCenter(tester, find.text('Add the widget'));
      await tester.tap(find.text('Add the widget'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Long-press an empty spot'), findsOneWidget);
    });
  });

  group('install the web app (iPhone)', () {
    testWidgets('a browser tab shows the iPhone steps; dismissing sticks', (
      tester,
    ) async {
      await pump(
        tester,
        await signedInPairedBackend(),
        inBrowser: true,
        ios: true,
      );
      expect(find.text('Add the app to your home screen'), findsOneWidget);
      expect(find.textContaining('Add to Home Screen'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(InstallAppCard),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add the app to your home screen'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('home.installHintDismissed'), isTrue);
    });

    testWidgets('the installed app (or Android) shows no install hint', (
      tester,
    ) async {
      await pump(tester, await signedInPairedBackend());
      expect(find.text('Add the app to your home screen'), findsNothing);
    });

    testWidgets('Settings explains installing on other browsers', (
      tester,
    ) async {
      await pump(tester, await signedInPairedBackend(), inBrowser: true);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await scrollToCenter(
        tester,
        find.text('Add the app to your home screen'),
      );
      await tester.tap(find.text('Add the app to your home screen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Install app'), findsOneWidget);
    });
  });
}
