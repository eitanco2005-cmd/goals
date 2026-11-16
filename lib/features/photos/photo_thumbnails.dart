import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'photo_providers.dart';
import 'photo_viewer.dart';

/// Locale-aware time of day a photo was taken, e.g. "9:41 AM" / "9:41".
String formatPhotoTime(BuildContext context, DateTime time) =>
    DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(time);

/// Fallback icon for photos of goals that are no longer in the challenge.
const unknownGoalIcon = '📷';

/// One [MemoryImage] per photo id: a photo's thumbnail never changes, and
/// reusing the provider avoids re-decoding (and flicker) whenever a snapshot
/// brings new byte buffers for the same photo.
final _thumbImages = <String, MemoryImage>{};

ImageProvider thumbnailImage(GoalPhoto photo) {
  if (_thumbImages.length > 200) _thumbImages.clear();
  return _thumbImages.putIfAbsent(photo.id, () => MemoryImage(photo.thumbnail));
}

/// A rounded, tappable photo thumbnail with optional corner badges.
class PhotoThumbnail extends StatelessWidget {
  const PhotoThumbnail({
    super.key,
    required this.photo,
    required this.size,
    required this.semanticsLabel,
    required this.onTap,
    this.bottomBadge,
    this.topBadge,
  });

  final GoalPhoto photo;
  final double size;
  final String semanticsLabel;
  final VoidCallback onTap;

  /// Small emoji shown in the bottom-start / top-end corners.
  final String? bottomBadge;
  final String? topBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(size * 0.27);
    final cache = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final label = photo.isPending
        ? '$semanticsLabel, ${AppLocalizations.of(context).photoUploading}'
        : semanticsLabel;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: scheme.surfaceContainerHighest,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: Ink.image(
                  image: ResizeImage.resizeIfNeeded(
                    cache,
                    null,
                    thumbnailImage(photo),
                  ),
                  fit: BoxFit.cover,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ),
            // Not on the server yet (offline or slow network): the partner
            // can't see it until it syncs.
            if (photo.isPending)
              PositionedDirectional(
                start: 3,
                top: 3,
                child: Container(
                  key: const ValueKey('photo-pending'),
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: size * 0.3,
                    color: Colors.white,
                  ),
                ),
              ),
            if (bottomBadge case final badge?)
              PositionedDirectional(
                start: -3,
                bottom: -3,
                child: _Badge(emoji: badge, size: size * 0.36),
              ),
            if (topBadge case final badge?)
              PositionedDirectional(
                end: -3,
                top: -3,
                child: _Badge(emoji: badge, size: size * 0.36),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.58, height: 1.1),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// My photos for [goal] today, as a compact row under the goal's controls.
/// Collapses to nothing while there are none.
class GoalPhotoStrip extends ConsumerWidget {
  const GoalPhotoStrip({super.key, required this.goal, required this.title});

  final GoalDef goal;

  /// Localized goal title (for semantics).
  final String title;

  static const thumbSize = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final photos = ref.watch(myGoalPhotosProvider(goal.id));
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: AlignmentDirectional.topStart,
      child: photos.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsetsDirectional.only(top: 12),
              child: SizedBox(
                height: thumbSize,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final p = photos[i];
                    return PhotoThumbnail(
                      key: ValueKey('photo-${p.id}'),
                      photo: p,
                      size: thumbSize,
                      semanticsLabel: l.photoOpen(
                        title,
                        formatPhotoTime(context, p.createdAt),
                      ),
                      onTap: () => openPhotoViewer(
                        context,
                        photos: photos,
                        initialIndex: i,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// The partner's photos today (newest first) for the partner strip, each
/// with its goal's icon and the reaction I gave, if any.
class PartnerPhotoRow extends StatelessWidget {
  const PartnerPhotoRow({
    super.key,
    required this.photos,
    required this.goals,
    required this.myUid,
  });

  final List<GoalPhoto> photos;
  final List<GoalDef> goals;
  final String? myUid;

  static const thumbSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final byId = {for (final g in goals) g.id: g};
    return SizedBox(
      // Room for the badges that stick out of the thumbnails.
      height: thumbSize + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final p = photos[i];
          final goal = byId[p.goalId];
          final reaction = p.reactions[myUid];
          final time = formatPhotoTime(context, p.createdAt);
          return Center(
            child: PhotoThumbnail(
              key: ValueKey('photo-${p.id}'),
              photo: p,
              size: thumbSize,
              bottomBadge: goal?.icon ?? unknownGoalIcon,
              topBadge: reaction,
              semanticsLabel: [
                l.photoOpen(goal?.title(lang) ?? '', time),
                if (reaction != null) l.photoYourReaction(reaction),
              ].join('. '),
              onTap: () =>
                  openPhotoViewer(context, photos: photos, initialIndex: i),
            ),
          );
        },
      ),
    );
  }
}
