/// Core domain models shared by every layer of the app.
///
/// All models are immutable and serialise to/from plain maps so the same
/// shape is used by Firestore and by the in-memory demo backend.
library;

import 'dart:typed_data';

/// How a goal's value is entered.
enum GoalType {
  /// Tap +1 / -1 (water glasses, meals, sweets).
  counter,

  /// Free number (steps).
  number,

  /// Yes / no. Stored as 1 (kept) or 0 (broken).
  boolean,

  /// Duration in minutes (reading, social media).
  minutes,

  /// Weekly workout log – value is derived from [WorkoutEntry] items.
  workouts,
}

/// How the logged value is compared to [GoalDef.target].
enum Comparison { atLeast, atMost, exactly }

enum GoalPeriod { daily, weekly }

enum WorkoutType { run, strength, other }

/// Result of evaluating one goal for one day (or week).
enum GoalStatus {
  /// Target reached.
  met,

  /// Value logged but the target is not reached (or limit exceeded).
  notMet,

  /// Nothing logged yet.
  unlogged,
}

/// Definition of a single goal inside a challenge.
class GoalDef {
  const GoalDef({
    required this.id,
    required this.titleHe,
    required this.titleEn,
    required this.type,
    required this.comparison,
    required this.target,
    required this.period,
    required this.icon,
    this.step = 1,
    this.requirements = const {},
  });

  final String id;
  final String titleHe;
  final String titleEn;
  final GoalType type;
  final Comparison comparison;

  /// Numeric target. For boolean goals this is 1.
  final num target;
  final GoalPeriod period;

  /// An emoji used as the goal's icon (keeps the widget/web simple).
  final String icon;

  /// Increment used by +/- buttons (e.g. 15 for minutes, 1000 for steps).
  final num step;

  /// Extra requirements, used by the weekly workouts goal:
  /// `{'run': 1, 'strength': 2, 'minMinutes': 30}`.
  final Map<String, num> requirements;

  String title(String languageCode) => languageCode == 'he' ? titleHe : titleEn;

  GoalDef copyWith({
    String? titleHe,
    String? titleEn,
    Comparison? comparison,
    num? target,
    num? step,
    Map<String, num>? requirements,
  }) =>
      GoalDef(
        id: id,
        titleHe: titleHe ?? this.titleHe,
        titleEn: titleEn ?? this.titleEn,
        type: type,
        comparison: comparison ?? this.comparison,
        target: target ?? this.target,
        period: period,
        icon: icon,
        step: step ?? this.step,
        requirements: requirements ?? this.requirements,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'titleHe': titleHe,
        'titleEn': titleEn,
        'type': type.name,
        'comparison': comparison.name,
        'target': target,
        'period': period.name,
        'icon': icon,
        'step': step,
        'requirements': requirements,
      };

  factory GoalDef.fromMap(Map<String, dynamic> m) => GoalDef(
        id: m['id'] as String,
        titleHe: m['titleHe'] as String,
        titleEn: m['titleEn'] as String,
        type: GoalType.values.byName(m['type'] as String),
        comparison: Comparison.values.byName(m['comparison'] as String),
        target: m['target'] as num,
        period: GoalPeriod.values.byName(m['period'] as String),
        icon: m['icon'] as String,
        step: (m['step'] as num?) ?? 1,
        requirements: Map<String, num>.from(
            (m['requirements'] as Map?)?.cast<String, num>() ?? const {}),
      );
}

/// A challenge round: a date range plus the goals for that range.
class Challenge {
  const Challenge({
    required this.id,
    required this.pairId,
    required this.startDate,
    required this.endDate,
    required this.goals,
  });

  final String id;
  final String pairId;

  /// Day keys (`yyyy-MM-dd`), inclusive.
  final String startDate;
  final String endDate;
  final List<GoalDef> goals;

  List<GoalDef> get dailyGoals =>
      goals.where((g) => g.period == GoalPeriod.daily).toList();
  List<GoalDef> get weeklyGoals =>
      goals.where((g) => g.period == GoalPeriod.weekly).toList();

  Map<String, dynamic> toMap() => {
        'id': id,
        'pairId': pairId,
        'startDate': startDate,
        'endDate': endDate,
        'goals': goals.map((g) => g.toMap()).toList(),
      };

  factory Challenge.fromMap(Map<String, dynamic> m) => Challenge(
        id: m['id'] as String,
        pairId: m['pairId'] as String,
        startDate: m['startDate'] as String,
        endDate: m['endDate'] as String,
        goals: (m['goals'] as List)
            .map((e) => GoalDef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// The signed-in account (auth layer only).
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});
  final String uid;
  final String? email;
  final String? displayName;
}

/// Per-user profile document.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.languageCode = 'he',
    this.pairId,
  });

  final String uid;
  final String displayName;

  /// 'he' or 'en'.
  final String languageCode;
  final String? pairId;

  UserProfile copyWith({
    String? displayName,
    String? languageCode,
    String? pairId,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        languageCode: languageCode ?? this.languageCode,
        pairId: pairId ?? this.pairId,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'languageCode': languageCode,
        'pairId': pairId,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        uid: m['uid'] as String,
        displayName: (m['displayName'] as String?) ?? '',
        languageCode: (m['languageCode'] as String?) ?? 'he',
        pairId: m['pairId'] as String?,
      );
}

/// Two people doing the challenge together.
class Pair {
  const Pair({
    required this.id,
    required this.memberUids,
    required this.memberNames,
    required this.inviteCode,
    this.activeChallengeId,
  });

  final String id;

  /// 1 member until the partner joins, then 2.
  final List<String> memberUids;

  /// uid -> display name, so each side can show the partner's name.
  final Map<String, String> memberNames;
  final String inviteCode;
  final String? activeChallengeId;

  bool get isComplete => memberUids.length == 2;

  String? partnerOf(String uid) =>
      memberUids.where((u) => u != uid).firstOrNull;

  Map<String, dynamic> toMap() => {
        'id': id,
        'memberUids': memberUids,
        'memberNames': memberNames,
        'inviteCode': inviteCode,
        'activeChallengeId': activeChallengeId,
      };

  factory Pair.fromMap(Map<String, dynamic> m) => Pair(
        id: m['id'] as String,
        memberUids: List<String>.from(m['memberUids'] as List),
        memberNames:
            Map<String, String>.from((m['memberNames'] as Map?) ?? const {}),
        inviteCode: m['inviteCode'] as String,
        activeChallengeId: m['activeChallengeId'] as String?,
      );
}

/// Private, detailed log of one user for one day. Only the owner can read it.
class DailyLog {
  const DailyLog({
    required this.uid,
    required this.date,
    this.values = const {},
  });

  final String uid;

  /// Day key `yyyy-MM-dd`.
  final String date;

  /// goalId -> value. A missing key means "not logged yet".
  final Map<String, num> values;

  num? valueOf(String goalId) => values[goalId];

  DailyLog withValue(String goalId, num? value) {
    final next = Map<String, num>.from(values);
    if (value == null) {
      next.remove(goalId);
    } else {
      next[goalId] = value;
    }
    return DailyLog(uid: uid, date: date, values: next);
  }

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'date': date, 'values': values};

  factory DailyLog.fromMap(Map<String, dynamic> m) => DailyLog(
        uid: m['uid'] as String,
        date: m['date'] as String,
        values: Map<String, num>.from(
            (m['values'] as Map?)?.cast<String, num>() ?? const {}),
      );
}

/// Public summary of one user's day. This is all the partner can see
/// ("summary only" visibility): per-goal status plus the daily percentage.
class DaySummary {
  const DaySummary({
    required this.uid,
    required this.date,
    required this.statuses,
    required this.percent,
  });

  final String uid;
  final String date;
  final Map<String, GoalStatus> statuses;

  /// 0..100, share of daily goals met.
  final int percent;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'date': date,
        'statuses': statuses.map((k, v) => MapEntry(k, v.name)),
        'percent': percent,
      };

  factory DaySummary.fromMap(Map<String, dynamic> m) => DaySummary(
        uid: m['uid'] as String,
        date: m['date'] as String,
        statuses: ((m['statuses'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k as String, GoalStatus.values.byName(v as String)),
        ),
        percent: (m['percent'] as num).toInt(),
      );
}

/// One logged workout (used by the weekly workouts goal).
class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.uid,
    required this.date,
    required this.type,
    required this.minutes,
  });

  final String id;
  final String uid;
  final String date;
  final WorkoutType type;
  final int minutes;

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'date': date,
        'type': type.name,
        'minutes': minutes,
      };

  factory WorkoutEntry.fromMap(Map<String, dynamic> m) => WorkoutEntry(
        id: m['id'] as String,
        uid: m['uid'] as String,
        date: m['date'] as String,
        type: WorkoutType.values.byName(m['type'] as String),
        minutes: (m['minutes'] as num).toInt(),
      );
}

/// Reactions a partner can put on a photo.
const photoReactions = ['❤️', '💪', '🔥'];

/// A photo one partner attached to a goal on a given day.
///
/// Photos are deliberately shared with the partner (unlike detailed logs).
/// This object carries only metadata plus a small [thumbnail]; the full image
/// is loaded on demand with `PhotoRepository.loadFullImage`.
class GoalPhoto {
  const GoalPhoto({
    required this.id,
    required this.uid,
    required this.date,
    required this.goalId,
    required this.createdAt,
    required this.thumbnail,
    required this.width,
    required this.height,
    this.reactions = const {},
    this.isPending = false,
  });

  final String id;

  /// Owner (the partner who took the photo).
  final String uid;

  /// Logging day key `yyyy-MM-dd` the photo belongs to.
  final String date;
  final String goalId;
  final DateTime createdAt;

  /// JPEG, ~320px on the long side.
  final Uint8List thumbnail;

  /// Pixel size of the full image.
  final int width;
  final int height;

  /// uid -> one of [photoReactions]. Only the partner reacts.
  final Map<String, String> reactions;

  /// True while this photo's local write has not reached the server yet
  /// (Firestore `hasPendingWrites`). Client-only: never serialized by
  /// [toMap]. Always false in the memory backend.
  final bool isPending;

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'date': date,
        'goalId': goalId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'thumbnail': thumbnail,
        'width': width,
        'height': height,
        'reactions': reactions,
      };

  /// [thumbnail] must already be converted to [Uint8List] by the caller
  /// (Firestore returns a `Blob`). [isPending] comes from the snapshot
  /// metadata, not from the map.
  factory GoalPhoto.fromMap(Map<String, dynamic> m,
          {bool isPending = false}) =>
      GoalPhoto(
        id: m['id'] as String,
        uid: m['uid'] as String,
        date: m['date'] as String,
        goalId: m['goalId'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['createdAt'] as num).toInt()),
        thumbnail: m['thumbnail'] as Uint8List,
        width: (m['width'] as num).toInt(),
        height: (m['height'] as num).toInt(),
        reactions:
            Map<String, String>.from((m['reactions'] as Map?) ?? const {}),
        isPending: isPending,
      );
}
