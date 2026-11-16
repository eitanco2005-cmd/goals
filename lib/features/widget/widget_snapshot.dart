import 'dart:convert';

import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';

/// Max partner photos kept for the home-screen widget (newest first).
const maxWidgetPhotos = 10;

/// One photo shown by the widget: a local JPEG file plus its caption.
class WidgetPhoto {
  const WidgetPhoto({
    required this.id,
    required this.path,
    required this.caption,
  });

  final String id;

  /// Absolute path of the JPEG on the device.
  final String path;

  /// e.g. "🥗 Vegetables with every meal · 13:20".
  final String caption;

  Map<String, dynamic> toJson() => {'id': id, 'path': path, 'caption': caption};
}

/// Everything the native Android widget renders. All text is already
/// localized here, so the Kotlin side needs no translations.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.title,
    required this.status,
    required this.emptyText,
    required this.rtl,
    required this.photos,
    required this.updatedAt,
  });

  /// "Noa · 62% today".
  final String title;

  /// Met goals at a glance: "5/9 · 💧👟🥗🍽️📖".
  final String status;

  /// Shown instead of photos when there are none yet.
  final String emptyText;

  /// Hebrew layout.
  final bool rtl;

  /// Newest first; the widget rotates through them.
  final List<WidgetPhoto> photos;

  /// Milliseconds since epoch (debugging / staleness).
  final int updatedAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'status': status,
    'emptyText': emptyText,
    'rtl': rtl,
    'photos': [for (final p in photos) p.toJson()],
    'updatedAt': updatedAt,
  };

  String encode() => jsonEncode(toJson());
}

/// Another member of the group, as the widget shows them.
class WidgetMember {
  const WidgetMember({
    required this.uid,
    required this.name,
    required this.summary,
  });

  final String uid;
  final String name;

  /// Their public summary of today (null until they log something).
  final DaySummary? summary;
}

/// Builds the widget content from the other members' public data only
/// (summaries and shared photos, never their detailed logs).
///
/// [photos] must be the other members' photos of today, newest first, and
/// [paths] maps photo ids to local files; photos without a file are skipped.
/// With one other member the widget is about them; with several, the title
/// lists everyone's % and each caption names who took the photo.
WidgetSnapshot buildWidgetSnapshot({
  required AppLocalizations l,
  required List<WidgetMember> members,
  required List<GoalDef> goals,
  required List<GoalPhoto> photos,
  required Map<String, String> paths,
  DateTime? now,
}) {
  final lang = l.localeName.substring(0, 2);
  final daily = goals.where((g) => g.period == GoalPeriod.daily).toList();
  final byId = {for (final g in goals) g.id: g};
  final names = {for (final m in members) m.uid: m.name};
  final single = members.length == 1 ? members.single : null;

  final String title;
  final String status;
  final String emptyText;
  if (single != null) {
    final metIcons = [
      for (final g in daily)
        if (single.summary?.statuses[g.id] == GoalStatus.met) g.icon,
    ];
    title = l.widgetTitle(single.name, single.summary?.percent ?? 0);
    status = [
      l.widgetGoalsDone(metIcons.length, daily.length),
      if (metIcons.isNotEmpty) metIcons.join(),
    ].join(' · ');
    emptyText = l.widgetNoPhotos(single.name);
  } else {
    // Highest % first: a friendly nudge.
    final ranked = [...members]
      ..sort(
        (a, b) => (b.summary?.percent ?? 0).compareTo(a.summary?.percent ?? 0),
      );
    title = [
      for (final m in ranked)
        l.widgetMemberPercent(m.name, m.summary?.percent ?? 0),
    ].join(' · ');
    status = l.widgetGroupPhotos(photos.length);
    emptyText = l.widgetNoPhotosGroup;
  }

  return WidgetSnapshot(
    title: title,
    status: status,
    emptyText: emptyText,
    rtl: lang == 'he',
    photos: [
      for (final p in photos.take(maxWidgetPhotos))
        if (paths[p.id] case final path?)
          WidgetPhoto(
            id: p.id,
            path: path,
            caption: [
              if (single == null && names[p.uid] != null) names[p.uid]!,
              if (byId[p.goalId] case final g?) '${g.icon} ${g.title(lang)}',
              _hhmm(p.createdAt),
            ].join(' · '),
          ),
    ],
    updatedAt: (now ?? DateTime.now()).millisecondsSinceEpoch,
  );
}

/// 24-hour "13:05". Formatted by hand: the background isolate that refreshes
/// the widget has no initialized intl date symbols.
String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
