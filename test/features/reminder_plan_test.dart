import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/features/reminders/reminder_plan.dart';

void main() {
  const both = ReminderSettings(eveningEnabled: true, middayEnabled: true);

  test('nothing planned when reminders are off', () {
    expect(
      planReminders(
        settings: const ReminderSettings(),
        now: DateTime(2026, 11, 16, 10),
        openToday: const ['Water'],
      ),
      isEmpty,
    );
  });

  test('today mentions open goals; later days are generic', () {
    final plan = planReminders(
      settings: both,
      now: DateTime(2026, 11, 16, 10),
      openToday: const ['Water', 'Reading'],
    );
    expect(plan, hasLength(2 * reminderDaysAhead));
    final first = plan.first;
    expect(first.kind, ReminderKind.midday);
    expect(first.at, DateTime(2026, 11, 16, 13));
    expect(first.openGoals, ['Water', 'Reading']);
    expect(plan[1].at, DateTime(2026, 11, 16, 21, 30));
    expect(plan[2].openGoals, isNull);
    expect(plan.map((p) => p.id).toSet(), hasLength(plan.length));
  });

  test('past times today are skipped; a fully logged today too', () {
    final late = planReminders(
      settings: both,
      now: DateTime(2026, 11, 16, 15),
      openToday: const ['Water'],
    );
    expect(late.first.kind, ReminderKind.evening);
    expect(late.first.dayKey, '2026-11-16');

    final done = planReminders(
      settings: both,
      now: DateTime(2026, 11, 16, 10),
      openToday: const [],
    );
    expect(done.first.dayKey, '2026-11-17');
  });

  test('a check after midnight belongs to the logging day before', () {
    final plan = planReminders(
      settings: const ReminderSettings(
        eveningEnabled: true,
        eveningMinutes: 30,
      ),
      now: DateTime(2026, 11, 16, 22),
      openToday: const ['Water'],
    );
    expect(plan.first.at, DateTime(2026, 11, 17, 0, 30));
    expect(plan.first.dayKey, '2026-11-16');
  });

  test('stops at the end of the challenge', () {
    final plan = planReminders(
      settings: both,
      now: DateTime(2026, 11, 16, 10),
      openToday: const ['Water'],
      challengeEnd: '2026-11-17',
    );
    expect(plan.map((p) => p.dayKey).toSet(), {'2026-11-16', '2026-11-17'});
  });
}
