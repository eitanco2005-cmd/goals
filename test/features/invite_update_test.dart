import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/features/invite/invite.dart';
import 'package:goals_challenge/features/pairing/pairing_screen.dart';
import 'package:goals_challenge/features/update/update_check.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

class FakeSharer implements Sharer {
  FakeSharer({this.works = true});
  final bool works;
  final shared = <String>[];

  @override
  Future<bool> share(String text) async {
    shared.add(text);
    return works;
  }
}

class FakeLinks implements IncomingLinks {
  FakeLinks([this.first]);
  final Uri? first;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> initial() async => first;

  @override
  Stream<Uri> get stream => controller.stream;
}

Future<void> pump(
  WidgetTester tester,
  MemoryBackend b, {
  List<Override> extra = const [],
  IncomingLinks? links,
  int? latestBuild,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...memoryOverrides(b, links: links, latestBuild: latestBuild),
        ...extra,
      ],
      child: const GoalsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<MemoryBackend> signedInUnpaired() async {
  final b = MemoryBackend(seedDemo: true);
  await b.signUp(
    email: 'me@x.com',
    password: 'secret1',
    displayName: 'Me',
    languageCode: 'en',
  );
  return b;
}

void main() {
  group('parseInviteCode', () {
    test('understands all link forms', () {
      expect(parseInviteCode(Uri.parse('goals://join/demo42')), 'DEMO42');
      expect(
        parseInviteCode(
          Uri.parse('https://our-challenge-e8f25.web.app/join/AB12CD'),
        ),
        'AB12CD',
      );
      expect(
        parseInviteCode(Uri.parse('https://x.app/?join=ab12cd')),
        'AB12CD',
      );
      expect(
        parseInviteCode(Uri.parse('https://x.app/download?code=Q1')),
        'Q1',
      );
      expect(parseInviteCode(Uri.parse('https://x.app/')), isNull);
      expect(parseInviteCode(Uri.parse('goals://other/ABC')), isNull);
    });
    test('the invite link points at the join page', () {
      expect(
        inviteLink('AB12CD'),
        'https://our-challenge-e8f25.web.app/join/AB12CD',
      );
    });
  });

  testWidgets('sharing the invite sends the link and the code', (tester) async {
    final sharer = FakeSharer();
    await pump(
      tester,
      await signedInSoloBackend(),
      extra: [sharerProvider.overrideWithValue(sharer)],
    );
    final share = find.byKey(const ValueKey('share-invite')).first;
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single, contains('/join/'));
    expect(sharer.shared.single, contains('Invite code:'));
  });

  testWidgets('without a share sheet the invite is copied instead', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(
      tester,
      await signedInSoloBackend(),
      extra: [sharerProvider.overrideWithValue(FakeSharer(works: false))],
    );
    final share = find.byKey(const ValueKey('share-invite')).first;
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(
      find.text('Invite copied – paste it into a message'),
      findsOneWidget,
    );
    expect(copied, contains('/join/'));
  });

  testWidgets(
    'an invite link opens "Join with a code" with the code filled in',
    (tester) async {
      final b = await signedInUnpaired();
      await pump(tester, b, links: FakeLinks(Uri.parse('goals://join/demo42')));
      expect(find.byType(PairingScreen), findsOneWidget);
      expect(find.text('DEMO42'), findsOneWidget);
      await tester.tap(find.text('Join challenge'));
      await tester.pumpAndSettle();
      expect(find.byType(PairingScreen), findsNothing);
      final pair = (await b.watchPair('demo-pair').first)!;
      expect(pair.memberUids, contains(b.currentUser!.uid));
    },
  );

  group('update notice', () {
    testWidgets('shown when a newer build is published; Update opens it', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        await signedInPairedBackend(),
        latestBuild: 21,
        extra: [
          currentBuildProvider.overrideWithValue(20),
          openUpdateProvider.overrideWithValue(() async => opened++),
        ],
      );
      expect(find.text('A new version of Goals is ready'), findsOneWidget);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('hidden when up to date, unknown, or dismissed', (
      tester,
    ) async {
      await pump(
        tester,
        await signedInPairedBackend(),
        latestBuild: 21,
        extra: [currentBuildProvider.overrideWithValue(21)],
      );
      expect(find.text('A new version of Goals is ready'), findsNothing);
    });

    testWidgets('can be dismissed', (tester) async {
      await pump(
        tester,
        await signedInPairedBackend(),
        latestBuild: 22,
        extra: [currentBuildProvider.overrideWithValue(20)],
      );
      final banner = find.ancestor(
        of: find.text('A new version of Goals is ready'),
        matching: find.byType(UpdateBanner),
      );
      await tester.tap(
        find.descendant(of: banner, matching: find.byIcon(Icons.close)),
      );
      await tester.pumpAndSettle();
      expect(find.text('A new version of Goals is ready'), findsNothing);
    });
  });
}
