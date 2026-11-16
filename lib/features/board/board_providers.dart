import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../domain/models.dart';

/// The challenge's days up to today (the part that can have data).
final boardDaysProvider = Provider<List<String>>((ref) {
  final challenge = ref.watch(challengeProvider).value;
  if (challenge == null) return const [];
  final today = ref.watch(todayKeyProvider);
  final end = challenge.endDate.compareTo(today) < 0
      ? challenge.endDate
      : today;
  if (end.compareTo(challenge.startDate) < 0) return const [];
  return dayKeysBetween(challenge.startDate, end);
});

/// A member's public day summaries over the whole challenge.
final memberSummariesProvider = StreamProvider.family<List<DaySummary>, String>(
  (ref, uid) {
    final challenge = ref.watch(challengeProvider).value;
    final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
    if (challenge == null || pairId == null) return Stream.value(const []);
    return ref
        .watch(logRepositoryProvider)
        .watchSummaries(
          pairId: pairId,
          uid: uid,
          from: challenge.startDate,
          to: challenge.endDate,
        );
  },
);

/// Everyone's photos of one day (the photo diary).
final dayPhotosProvider = StreamProvider.family<List<GoalPhoto>, String>((
  ref,
  date,
) {
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  if (pairId == null) return Stream.value(const []);
  return ref
      .watch(photoRepositoryProvider)
      .watchPhotos(pairId: pairId, from: date, to: date);
});

/// Sequential single-hue ramp for "share of daily goals met" (validated for
/// monotone lightness, step gaps and contrast against the card surface in
/// both themes). Index 0 = 1–25 % … index 4 = 100 %.
const boardRampLight = [
  Color(0xFF6CBF94),
  Color(0xFF4AA878),
  Color(0xFF2E9062),
  Color(0xFF1D734C),
  Color(0xFF0F5536),
];
const boardRampDark = [
  Color(0xFF2E6B4B),
  Color(0xFF36885C),
  Color(0xFF43A36E),
  Color(0xFF62BD88),
  Color(0xFF93DAAF),
];

/// Ramp color for a day's [percent], or null for 0 % / no data (drawn as an
/// empty cell instead).
Color? boardColor(int? percent, Brightness brightness) {
  if (percent == null || percent <= 0) return null;
  final ramp = brightness == Brightness.dark ? boardRampDark : boardRampLight;
  final i = percent >= 100 ? 4 : ((percent - 1) ~/ 25).clamp(0, 3);
  return ramp[i];
}
