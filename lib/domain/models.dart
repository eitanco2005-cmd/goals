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

/// Default goal titles reworded since challenges were created with them
/// (challenges keep a copy of their goals, so they're renamed on load).
const _renamedHe = {
  'לפחות שעה קריאה': 'מינימום שעה קריאה',
  'ממתק/חטיף אחד לכל היותר': 'מקסימום ממתק/חטיף אחד',
};

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
    this.requiresPhoto = false,
    this.unitHe = '',
    this.unitEn = '',
    this.hours = false,
    this.machineLang = '',
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

  /// The goal counts as met only when its owner also attached a photo of
  /// it that day (daily goals).
  final bool requiresPhoto;

  String title(String languageCode) => languageCode == 'he' ? titleHe : titleEn;

  /// Optional unit word for number goals ("pages", "km"); empty for none.
  final String unitHe;
  final String unitEn;

  String unit(String languageCode) => languageCode == 'he' ? unitHe : unitEn;

  /// A time goal set in hours: still stored in minutes, shown as h:mm.
  final bool hours;

  /// Which language's name/unit was machine-translated ('he' / 'en'), or
  /// empty when both were written by people. Editing that language counts
  /// as a correction; editing the other one translates again.
  final String machineLang;

  GoalDef copyWith({
    String? titleHe,
    String? titleEn,
    Comparison? comparison,
    num? target,
    num? step,
    Map<String, num>? requirements,
    bool? requiresPhoto,
    String? unitHe,
    String? unitEn,
    bool? hours,
    String? machineLang,
  }) => GoalDef(
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
    requiresPhoto: requiresPhoto ?? this.requiresPhoto,
    unitHe: unitHe ?? this.unitHe,
    unitEn: unitEn ?? this.unitEn,
    hours: hours ?? this.hours,
    machineLang: machineLang ?? this.machineLang,
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
    if (requiresPhoto) 'requiresPhoto': true,
    if (unitHe.isNotEmpty) 'unitHe': unitHe,
    if (unitEn.isNotEmpty) 'unitEn': unitEn,
    if (hours) 'hours': true,
    if (machineLang.isNotEmpty) 'machineLang': machineLang,
  };

  factory GoalDef.fromMap(Map<String, dynamic> m) => GoalDef(
    id: m['id'] as String,
    titleHe: _renamedHe[m['titleHe']] ?? m['titleHe'] as String,
    titleEn: m['titleEn'] as String,
    type: GoalType.values.byName(m['type'] as String),
    comparison: Comparison.values.byName(m['comparison'] as String),
    target: m['target'] as num,
    period: GoalPeriod.values.byName(m['period'] as String),
    icon: m['icon'] as String,
    // Goals in hours step by half an hour (early ones were saved with 15).
    step: m['hours'] == true && m['step'] == 15 ? 30 : (m['step'] as num?) ?? 1,
    requirements: Map<String, num>.from(
      (m['requirements'] as Map?)?.cast<String, num>() ?? const {},
    ),
    requiresPhoto: m['requiresPhoto'] == true,
    unitHe: (m['unitHe'] as String?) ?? '',
    unitEn: (m['unitEn'] as String?) ?? '',
    hours: m['hours'] == true,
    machineLang: (m['machineLang'] as String?) ?? '',
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
  }) => UserProfile(
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

/// Maximum number of people in one challenge group.
const maxGroupMembers = 8;

/// A challenge group: 1 person (just created) up to [maxGroupMembers].
///
/// Named `Pair` for historical reasons (the Firestore collection is still
/// `pairs`), but it is a group of any size.
class Pair {
  const Pair({
    required this.id,
    required this.memberUids,
    required this.memberNames,
    required this.inviteCode,
    this.activeChallengeId,
  });

  final String id;

  /// In joining order; the creator first.
  final List<String> memberUids;

  /// uid -> display name, so everyone can show the others' names.
  final Map<String, String> memberNames;
  final String inviteCode;
  final String? activeChallengeId;

  /// No one else can join.
  bool get isFull => memberUids.length >= maxGroupMembers;

  /// Everyone in the group except [uid], in joining order.
  List<String> othersOf(String uid) => [
    for (final u in memberUids)
      if (u != uid) u,
  ];

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
    memberNames: Map<String, String>.from(
      (m['memberNames'] as Map?) ?? const {},
    ),
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

  Map<String, dynamic> toMap() => {'uid': uid, 'date': date, 'values': values};

  factory DailyLog.fromMap(Map<String, dynamic> m) => DailyLog(
    uid: m['uid'] as String,
    date: m['date'] as String,
    values: Map<String, num>.from(
      (m['values'] as Map?)?.cast<String, num>() ?? const {},
    ),
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

/// Public summary of one member's week: met / not met per WEEKLY goal.
/// Like [DaySummary], it is all the other members can see — never the
/// workouts or counts behind it.
class WeekSummary {
  const WeekSummary({
    required this.uid,
    required this.weekStart,
    required this.statuses,
  });

  final String uid;

  /// Day key of the week's Sunday.
  final String weekStart;
  final Map<String, GoalStatus> statuses;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'weekStart': weekStart,
    'statuses': statuses.map((k, v) => MapEntry(k, v.name)),
  };

  factory WeekSummary.fromMap(Map<String, dynamic> m) => WeekSummary(
    uid: m['uid'] as String,
    weekStart: m['weekStart'] as String,
    statuses: ((m['statuses'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, GoalStatus.values.byName(v as String)),
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is WeekSummary &&
      other.uid == uid &&
      other.weekStart == weekStart &&
      other.statuses.length == statuses.length &&
      statuses.entries.every((e) => other.statuses[e.key] == e.value);

  @override
  int get hashCode => Object.hash(uid, weekStart, statuses.length);
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
  factory GoalPhoto.fromMap(Map<String, dynamic> m, {bool isPending = false}) =>
      GoalPhoto(
        id: m['id'] as String,
        uid: m['uid'] as String,
        date: m['date'] as String,
        goalId: m['goalId'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (m['createdAt'] as num).toInt(),
        ),
        thumbnail: m['thumbnail'] as Uint8List,
        width: (m['width'] as num).toInt(),
        height: (m['height'] as num).toInt(),
        reactions: Map<String, String>.from(
          (m['reactions'] as Map?) ?? const {},
        ),
        isPending: isPending,
      );
}
