import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/features/reminders/reminder_plan.dart';
import 'package:goals_challenge/features/reminders/reminders.dart';
import 'package:goals_challenge/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.allow = true});
  final bool allow;
  var permissionRequests = 0;
  List<ScheduledReminder> scheduled = const [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allow;
  }

  @override
  Future<void> replaceAll(List<ScheduledReminder> reminders) async =>
      scheduled = reminders;
}

Future<void> pump(
  WidgetTester tester,
  MemoryBackend b,
  FakeScheduler scheduler,
) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: memoryOverrides(b, reminders: scheduler),
      child: const GoalsApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  await scrollToCenter(tester, find.text('End-of-day check'));
}

Finder switchOf(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(Switch),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rendering: today names the open goals, later days are generic', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final out = renderReminders(en, [
      PlannedReminder(
        id: 100,
        kind: ReminderKind.evening,
        at: DateTime(2026, 11, 16, 21, 30),
        dayKey: '2026-11-16',
        openGoals: const ['8 glasses of water', '3 meals'],
      ),
      PlannedReminder(
        id: 200,
        kind: ReminderKind.midday,
        at: DateTime(2026, 11, 16, 13),
        dayKey: '2026-11-16',
        openGoals: const ['3 meals'],
      ),
      PlannedReminder(
        id: 101,
        kind: ReminderKind.evening,
        at: DateTime(2026, 11, 17, 21, 30),
        dayKey: '2026-11-17',
        openGoals: null,
      ),
    ]);
    expect(out[0].title, 'End-of-day check');
    expect(out[0].body, 'Still to log: 8 glasses of water, 3 meals');
    expect(out[1].body, '1 goal still open: 3 meals');
    expect(out[2].body, startsWith('How did today go?'));
  });

  testWidgets('turning on the end-of-day check schedules it', (tester) async {
    final scheduler = FakeScheduler();
    await pump(tester, await signedInPairedBackend(), scheduler);
    await tester.tap(switchOf('reminder-evening'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(scheduler.scheduled, isNotEmpty);
    expect(
      scheduler.scheduled.every((r) => r.title == 'End-of-day check'),
      isTrue,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('reminders.v1')?.first, '1');
  });

  testWidgets('without permission the reminder stays off', (tester) async {
    final scheduler = FakeScheduler(allow: false);
    await pump(tester, await signedInPairedBackend(), scheduler);
    await tester.tap(switchOf('reminder-evening'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(tester.widget<Switch>(switchOf('reminder-evening')).value, isFalse);
  });

  testWidgets('saved settings are restored on the next start', (tester) async {
    SharedPreferences.setMockInitialValues({
      'reminders.v1': ['0', '1290', '1', '780'],
    });
    final scheduler = FakeScheduler();
    await pump(tester, await signedInPairedBackend(), scheduler);
    expect(tester.widget<Switch>(switchOf('reminder-midday')).value, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(
      scheduler.scheduled.every((r) => r.title == 'Halfway through the day'),
      isTrue,
    );
  });

  testWidgets('tapping the row changes the time', (tester) async {
    final scheduler = FakeScheduler();
    await pump(tester, await signedInPairedBackend(), scheduler);
    await tester.tap(find.text('End-of-day check'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });
}
