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

/// Builds the widget content from the partner's public data only (summary
/// and shared photos — never their detailed log).
///
/// [photos] must be the partner's photos of today, newest first, and
/// [paths] maps photo ids to local files; photos without a file are skipped.
WidgetSnapshot buildWidgetSnapshot({
  required AppLocalizations l,
  required String partnerName,
  required DaySummary? summary,
  required List<GoalDef> goals,
  required List<GoalPhoto> photos,
  required Map<String, String> paths,
  DateTime? now,
}) {
  final daily = goals.where((g) => g.period == GoalPeriod.daily).toList();
  final percent = summary?.percent ?? 0;
  final metIcons = [
    for (final g in daily)
      if (summary?.statuses[g.id] == GoalStatus.met) g.icon,
  ];
  final byId = {for (final g in goals) g.id: g};

  return WidgetSnapshot(
    title: l.widgetTitle(partnerName, percent),
    status: [
      l.widgetGoalsDone(metIcons.length, daily.length),
      if (metIcons.isNotEmpty) metIcons.join(),
    ].join(' · '),
    emptyText: l.widgetNoPhotos(partnerName),
    rtl: l.localeName.startsWith('he'),
    photos: [
      for (final p in photos.take(maxWidgetPhotos))
        if (paths[p.id] case final path?)
          WidgetPhoto(
            id: p.id,
            path: path,
            caption: [
              if (byId[p.goalId] case final g?)
                '${g.icon} ${g.title(l.localeName.substring(0, 2))}',
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
