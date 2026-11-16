import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/today/today_format.dart';
import 'package:goals_challenge/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart' show Locale;

GoalDef _goal(String id) => defaultGoals.firstWhere((g) => g.id == id);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final he = lookupAppLocalizations(const Locale('he'));

  group('challengeDay', () {
    ChallengeDay day(String today) => challengeDay(
      startDate: '2026-03-01',
      endDate: '2026-03-31',
      today: today,
    );

    test('first, middle and last day', () {
      expect(day('2026-03-01'), const ChallengeDay(day: 1, total: 31));
      expect(day('2026-03-15'), const ChallengeDay(day: 15, total: 31));
      expect(day('2026-03-31'), const ChallengeDay(day: 31, total: 31));
    });

    test('is not skewed by daylight-saving changes', () {
      // Israel/EU DST starts in late March.
      expect(day('2026-03-29').day, 29);
      expect(day('2026-03-30').day, 30);
    });

    test('before start and after end', () {
      final before = day('2026-02-27');
      expect(before.notStarted, isTrue);
      expect(before.daysUntilStart, 2);
      expect(day('2026-04-01').ended, isTrue);
    });

    test('labels', () {
      expect(challengeDayLabel(en, day('2026-03-02')), 'Day 2 of 31');
      expect(challengeDayLabel(he, day('2026-03-02')), 'יום 2 מתוך 31');
      expect(
        challengeDayLabel(en, day('2026-02-28')),
        'The challenge starts tomorrow',
      );
      expect(
        challengeDayLabel(en, day('2026-02-25')),
        'The challenge starts in 4 days',
      );
      expect(challengeDayLabel(en, day('2026-04-02')), en.todayChallengeEnded);
    });
  });

  group('GoalFormatter.target', () {
    final fmtEn = GoalFormatter(en, 'en');
    final fmtHe = GoalFormatter(he, 'he');

    test('counter atLeast shows value / target', () {
      expect(fmtEn.target(_goal(GoalIds.water), 5), '5 / 8');
      expect(fmtEn.target(_goal(GoalIds.water), null), '0 / 8');
    });

    test('steps are grouped and carry a unit', () {
      expect(fmtEn.target(_goal(GoalIds.steps), 6400), '6,400 / 10,000 steps');
      expect(fmtHe.target(_goal(GoalIds.steps), 6400), '6,400 / 10,000 צעדים');
    });

    test('limits show the maximum', () {
      expect(fmtEn.target(_goal(GoalIds.socialMedia), 30), 'max 60 min');
      expect(fmtHe.target(_goal(GoalIds.socialMedia), 30), 'עד 60 דק׳');
      expect(fmtEn.target(_goal(GoalIds.sweets), null), 'max 1');
    });

    test('minutes atLeast and exact counters', () {
      expect(fmtEn.target(_goal(GoalIds.reading), 45), '45 / 60 min');
      expect(fmtEn.target(_goal(GoalIds.meals), 2), '2 / 3');
    });

    test('yes/no goals have no target text', () {
      expect(fmtEn.target(_goal(GoalIds.veggies), 1), isNull);
    });
  });

  test('greetingFor covers the whole day', () {
    expect(greetingFor(en, 7), en.todayGreetingMorning);
    expect(greetingFor(en, 13), en.todayGreetingAfternoon);
    expect(greetingFor(en, 19), en.todayGreetingEvening);
    expect(greetingFor(en, 23), en.todayGreetingNight);
    expect(greetingFor(en, 2), en.todayGreetingNight);
  });
}
