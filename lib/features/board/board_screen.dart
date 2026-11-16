import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../domain/board_stats.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../photos/photo_thumbnails.dart';
import '../photos/photo_viewer.dart';
import 'board_providers.dart';

/// The challenge at a glance: a calendar heatmap per member (share of daily
/// goals met), streaks and averages, how often I meet each goal, and a photo
/// diary behind every day.
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final challenge = ref.watch(challengeProvider).value;
    final pair = ref.watch(pairProvider).value;
    final myUid = ref.watch(authStateProvider.select((a) => a.value?.uid));
    final others = ref.watch(otherMemberUidsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = ref.watch(todayKeyProvider);

    final Widget body;
    if (challenge == null || myUid == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (today.compareTo(challenge.startDate) < 0) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l.boardNotStarted(
              DateFormat.yMMMd(locale).format(parseDayKey(challenge.startDate)),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 32),
        children: [
          const _Legend(),
          const SizedBox(height: 12),
          _MemberCard(
            key: const ValueKey('board-me'),
            uid: myUid,
            name: l.boardYou,
            challenge: challenge,
          ),
          for (final uid in others) ...[
            const SizedBox(height: 12),
            _MemberCard(
              key: ValueKey('board-$uid'),
              uid: uid,
              name: pair?.memberNames[uid] ?? l.todayPartnerFallbackName,
              challenge: challenge,
            ),
          ],
          const SizedBox(height: 12),
          _GoalRatesCard(uid: myUid, dailyGoals: challenge.dailyGoals),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.navBoard,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// "Daily goals met: 0 % ▢▢▢▢▢ 100 %" plus how streaks are counted.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.boardLegend, style: theme.textTheme.labelLarge),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('0%', style: muted),
                const SizedBox(width: 4),
                for (final p in [0, 25, 50, 75, 99, 100])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 3),
                    child: _Cell(size: 14, percent: p, isFuture: false),
                  ),
                const SizedBox(width: 1),
                Text('100%', style: muted),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l.boardStreakHint(goodDayPercent), style: muted),
      ],
    );
  }
}

/// One heatmap square. Empty (outlined) for 0 % / no data, faint for days
/// still to come.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.size,
    required this.percent,
    required this.isFuture,
    this.isToday = false,
    this.label,
  });

  final double size;
  final int? percent;
  final bool isFuture;
  final bool isToday;

  /// Day of the month, drawn inside bigger cells.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = isFuture
        ? null
        : boardColor(percent, Theme.of(context).brightness);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill ?? (isFuture ? null : scheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(math.min(4, size / 4)),
        border: isToday
            ? Border.all(color: scheme.onSurface, width: 1.5)
            : (fill == null
                  ? Border.all(
                      color: scheme.outlineVariant.withValues(
                        alpha: isFuture ? 0.35 : 0.8,
                      ),
                    )
                  : null),
      ),
      alignment: Alignment.center,
      child: label == null
          ? null
          : Text(
              label!,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: fill != null
                    ? (ThemeData.estimateBrightnessForColor(fill) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87)
                    : scheme.onSurfaceVariant.withValues(
                        alpha: isFuture ? 0.45 : 0.9,
                      ),
              ),
            ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    super.key,
    required this.uid,
    required this.name,
    required this.challenge,
  });

  final String uid;
  final String name;
  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summaries =
        ref.watch(memberSummariesProvider(uid)).value ?? const <DaySummary>[];
    final percentByDay = {for (final s in summaries) s.date: s.percent};
    final days = ref.watch(boardDaysProvider);
    final today = ref.watch(todayKeyProvider);
    // Today is still in progress: leave it out of the average.
    final finished = days.where((d) => d != today).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(
                  label: l.boardStreak,
                  value: l.boardDays(currentStreak(percentByDay, today)),
                ),
                _Stat(
                  label: l.boardBestStreak,
                  value: l.boardDays(bestStreak(percentByDay, days)),
                ),
                _Stat(
                  label: l.boardAverage,
                  value:
                      '${averagePercent(percentByDay, finished.isEmpty ? days : finished)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Heatmap(
              challenge: challenge,
              percentByDay: percentByDay,
              today: today,
            ),
            if (finished.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l.boardEmptyHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Weeks as columns (Sunday on top), the whole challenge. Scrolls sideways
/// when the challenge is too long to fit, starting at the latest week.
class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.challenge,
    required this.percentByDay,
    required this.today,
  });

  final Challenge challenge;
  final Map<String, int> percentByDay;
  final String today;

  static const gap = 4.0;
  static const minCell = 14.0;
  static const maxCell = 44.0;

  /// Cells at least this big show the day of the month.
  static const labelCell = 22.0;
  static const dayLabelWidth = 22.0;
  static const monthHeader = 18.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final firstWeek = weekStart(parseDayKey(challenge.startDate));
    final lastWeek = weekStart(parseDayKey(challenge.endDate));
    final weeks = [
      for (
        var w = firstWeek;
        !w.isAfter(lastWeek);
        w = DateTime(w.year, w.month, w.day + 7)
      )
        w,
    ];

    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final weekdayFormat = DateFormat('EEEEE', locale);
    final monthFormat = DateFormat.MMM(locale);

    // Month name above the first week and above each week where one starts.
    String? monthLabel(int i, DateTime week) {
      final first = i == 0 ? parseDayKey(challenge.startDate) : null;
      if (first != null) return monthFormat.format(first);
      for (var d = 0; d < 7; d++) {
        final date = DateTime(week.year, week.month, week.day + d);
        if (date.day == 1 && dayKey(date).compareTo(challenge.endDate) <= 0) {
          return monthFormat.format(date);
        }
      }
      return null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - dayLabelWidth - gap;
        final fit = (available - gap * (weeks.length - 1)) / weeks.length;
        final cell = fit.clamp(minCell, maxCell).toDouble();
        final showNumbers = cell >= labelCell;
        // A month name needs ~3 narrow columns: when two would collide, keep
        // the later one (where the month actually starts).
        final monthLabels = [
          for (final (i, w) in weeks.indexed) monthLabel(i, w),
        ];
        final span = (36 / (cell + gap)).ceil();
        for (var i = 0; i < monthLabels.length; i++) {
          if (monthLabels[i] == null) continue;
          for (var j = i + 1; j < i + span && j < monthLabels.length; j++) {
            if (monthLabels[j] != null) {
              monthLabels[i] = null;
              break;
            }
          }
        }

        final dayLabels = Column(
          children: [
            const SizedBox(height: monthHeader),
            for (var d = 0; d < 7; d++) ...[
              if (d > 0) const SizedBox(height: gap),
              SizedBox(
                width: dayLabelWidth,
                height: cell,
                child: Center(
                  child: Text(
                    weekdayFormat.format(
                      DateTime(
                        firstWeek.year,
                        firstWeek.month,
                        firstWeek.day + d,
                      ),
                    ),
                    style: muted,
                  ),
                ),
              ),
            ],
          ],
        );

        final grid = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, week) in weeks.indexed) ...[
              if (i > 0) const SizedBox(width: gap),
              Column(
                children: [
                  SizedBox(
                    width: cell,
                    height: monthHeader,
                    child: OverflowBox(
                      maxWidth: cell * 3,
                      alignment: AlignmentDirectional.topStart,
                      child: Text(
                        monthLabels[i] ?? '',
                        style: muted,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  for (var d = 0; d < 7; d++) ...[
                    if (d > 0) const SizedBox(height: gap),
                    Builder(
                      builder: (context) {
                        final date = DateTime(
                          week.year,
                          week.month,
                          week.day + d,
                        );
                        final key = dayKey(date);
                        final inRange =
                            key.compareTo(challenge.startDate) >= 0 &&
                            key.compareTo(challenge.endDate) <= 0;
                        if (!inRange) return SizedBox.square(dimension: cell);
                        final future = key.compareTo(today) > 0;
                        final percent = percentByDay[key];
                        final dateLabel = DateFormat.MMMEd(locale).format(date);
                        final value = percent == null
                            ? l.boardNoData
                            : '$percent%';
                        final square = _Cell(
                          size: cell,
                          percent: percent,
                          isFuture: future,
                          isToday: key == today,
                          label: showNumbers ? '${date.day}' : null,
                        );
                        if (future) return square;
                        return Tooltip(
                          message: '$dateLabel · $value',
                          child: Semantics(
                            button: true,
                            label: l.boardCellLabel(dateLabel, value),
                            child: InkWell(
                              key: ValueKey('cell-$key'),
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => showDayDiary(context, key),
                              child: square,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
        final width = weeks.length * cell + (weeks.length - 1) * gap;
        final Widget weeksView = width <= available
            ? grid
            : Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: grid,
                ),
              );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dayLabels,
            const SizedBox(width: gap),
            weeksView,
          ],
        );
      },
    );
  }
}

/// How often I met each daily goal so far (thin single-hue bars).
class _GoalRatesCard extends ConsumerWidget {
  const _GoalRatesCard({required this.uid, required this.dailyGoals});

  final String uid;
  final List<GoalDef> dailyGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final today = ref.watch(todayKeyProvider);
    final days = ref.watch(boardDaysProvider).where((d) => d != today).toList();
    if (days.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.boardGoalRates,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.boardGoalRatesSoon,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final summaries =
        ref.watch(memberSummariesProvider(uid)).value ?? const <DaySummary>[];
    final rates = goalSuccessRates(summaries, dailyGoals, days);
    final barColor = boardColor(76, theme.brightness)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.boardGoalRates,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final g in dailyGoals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Semantics(
                  label: '${g.title(lang)}: ${rates[g.id]}%',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(g.icon, textDirection: TextDirection.ltr),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              g.title(lang),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${rates[g.id]}%',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (rates[g.id] ?? 0) / 100,
                          minHeight: 6,
                          color: barColor,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The photo diary of one day: everyone's % and photos.
Future<void> showDayDiary(BuildContext context, String date) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DayDiary(date: date),
    );

class _DayDiary extends ConsumerWidget {
  const _DayDiary({required this.date});
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lang = Localizations.localeOf(context).languageCode;
    final pair = ref.watch(pairProvider).value;
    final myUid = ref.watch(authStateProvider.select((a) => a.value?.uid));
    final goals = ref.watch(challengeProvider).value?.goals ?? const [];
    final photos =
        ref.watch(dayPhotosProvider(date)).value ?? const <GoalPhoto>[];
    final members = [?myUid, ...?pair?.memberUids.where((u) => u != myUid)];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
          children: [
            Text(
              DateFormat.yMMMMEEEEd(locale).format(parseDayKey(date)),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (photos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.boardNoPhotos,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final uid in members)
              Builder(
                builder: (context) {
                  final summary =
                      (ref.watch(memberSummariesProvider(uid)).value ??
                              const <DaySummary>[])
                          .where((s) => s.date == date)
                          .firstOrNull;
                  final theirs = [
                    for (final p in photos)
                      if (p.uid == uid) p,
                  ];
                  return Padding(
                    key: ValueKey('diary-$uid'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                uid == myUid
                                    ? l.boardYou
                                    : pair?.memberNames[uid] ??
                                          l.todayPartnerFallbackName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              summary == null
                                  ? l.boardNoData
                                  : '${summary.percent}%',
                            ),
                          ],
                        ),
                        if (theirs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (i, p) in theirs.indexed)
                                Builder(
                                  builder: (context) {
                                    final goal = goals
                                        .where((g) => g.id == p.goalId)
                                        .firstOrNull;
                                    return PhotoThumbnail(
                                      key: ValueKey('diary-photo-${p.id}'),
                                      photo: p,
                                      size: 72,
                                      semanticsLabel:
                                          '${goal?.title(lang) ?? ''}, ${formatPhotoTime(context, p.createdAt)}',
                                      bottomBadge: goal?.icon,
                                      onTap: () => openPhotoViewer(
                                        context,
                                        photos: theirs,
                                        initialIndex: i,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
