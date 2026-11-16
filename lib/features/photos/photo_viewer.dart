import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart'
    show HapticFeedback, LogicalKeyboardKey, SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'photo_providers.dart';
import 'photo_thumbnails.dart';

/// Opens the full-screen viewer over [photos], starting at [initialIndex].
Future<void> openPhotoViewer(
  BuildContext context, {
  required List<GoalPhoto> photos,
  required int initialIndex,
}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) =>
        PhotoViewer(photos: photos, initialIndex: initialIndex),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  ),
);

/// Full-screen, swipeable photo viewer.
///
/// Partner photos get a ❤️ 💪 🔥 reaction bar; my own photos show the
/// partner's reaction and can be deleted. Photo data stays live for today's
/// photos (reactions update while open); other days show [photos] as given.
class PhotoViewer extends ConsumerStatefulWidget {
  const PhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  final List<GoalPhoto> photos;
  final int initialIndex;

  @override
  ConsumerState<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<PhotoViewer> {
  late final List<GoalPhoto> _photos = [...widget.photos];
  late int _index = widget.initialIndex.clamp(0, _photos.length - 1);
  late final _pages = PageController(initialPage: _index);

  /// Reactions being saved: photo id -> emoji (null = being removed).
  final _pendingReactions = <String, String?>{};
  bool _zoomed = false;
  bool _chromeVisible = true;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _toggleReaction(GoalPhoto photo, String emoji) async {
    final uid = ref.read(authStateProvider).value?.uid;
    final pairId = ref.read(pairProvider).value?.id;
    if (uid == null || pairId == null) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final current = _myReaction(photo, uid);
    final next = current == emoji ? null : emoji;
    HapticFeedback.selectionClick();
    setState(() => _pendingReactions[photo.id] = next);
    try {
      await ref
          .read(photoRepositoryProvider)
          .setReaction(
            pairId: pairId,
            photoId: photo.id,
            uid: uid,
            emoji: next,
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
    } finally {
      if (mounted && _pendingReactions[photo.id] == next) {
        setState(() => _pendingReactions.remove(photo.id));
      }
    }
  }

  String? _myReaction(GoalPhoto photo, String uid) =>
      _pendingReactions.containsKey(photo.id)
      ? _pendingReactions[photo.id]
      : photo.reactions[uid];

  Future<void> _delete(GoalPhoto photo) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final pairId = ref.read(pairProvider).value?.id;
    if (pairId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteDialog(),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(photoRepositoryProvider)
          .deletePhoto(pairId: pairId, photoId: photo.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
      return;
    }
    HapticFeedback.mediumImpact();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.photoDeleted)));
    if (!mounted) return;
    if (_photos.length == 1) {
      navigator.pop();
      return;
    }
    setState(() {
      _photos.removeWhere((p) => p.id == photo.id);
      _index = _index.clamp(0, _photos.length - 1);
      _zoomed = false;
    });
  }

  /// Drops today's photos that disappeared from the live list (the owner
  /// deleted them), so nobody reacts to a photo that no longer exists.
  /// Closes the viewer when nothing is left.
  void _syncDeleted(List<GoalPhoto> live) {
    final today = ref.read(todayKeyProvider);
    final ids = {for (final p in live) p.id};
    final current = _photos[_index].id;
    final kept = [
      for (final p in _photos)
        if (p.date != today || ids.contains(p.id)) p,
    ];
    if (kept.length == _photos.length) return;
    if (kept.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    final keptIndex = kept.indexWhere((p) => p.id == current);
    final nextIndex = (keptIndex >= 0 ? keptIndex : _index).clamp(
      0,
      kept.length - 1,
    );
    setState(() {
      _photos
        ..clear()
        ..addAll(kept);
      _index = nextIndex;
      _zoomed = false;
    });
    if (_pages.hasClients) _pages.jumpToPage(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todayPhotosProvider, (_, next) {
      if (next case AsyncData(:final value)) _syncDeleted(value);
    });
    final live = {
      for (final p in ref.watch(todayPhotosProvider).value ?? const []) p.id: p,
    };
    final myUid = ref.watch(authStateProvider.select((a) => a.value?.uid));
    final pair = ref.watch(pairProvider).value;
    final goals = ref.watch(challengeProvider).value?.goals ?? const [];
    final photo = live[_photos[_index].id] ?? _photos[_index];
    final mine = photo.uid == myUid;
    final partnerUid = myUid == null ? null : pair?.partnerOf(myUid);
    final partnerReaction = mine ? photo.reactions[partnerUid] : null;
    final goal = goals.where((g) => g.id == photo.goalId).firstOrNull;
    final l = AppLocalizations.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _chromeVisible = !_chromeVisible),
                    child: PageView.builder(
                      controller: _pages,
                      physics: _zoomed
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      itemCount: _photos.length,
                      onPageChanged: (i) => setState(() {
                        _index = i;
                        _zoomed = false;
                      }),
                      itemBuilder: (context, i) => _PhotoPage(
                        key: ValueKey(_photos[i].id),
                        photo: _photos[i],
                        onZoomChanged: (z) {
                          if (z != _zoomed) setState(() => _zoomed = z);
                        },
                      ),
                    ),
                  ),
                ),
                _Chrome(
                  visible: _chromeVisible,
                  alignment: Alignment.topCenter,
                  child: _TopBar(
                    goalIcon: goal?.icon ?? unknownGoalIcon,
                    title:
                        goal?.title(
                          Localizations.localeOf(context).languageCode,
                        ) ??
                        '',
                    subtitle: [
                      ?pair?.memberNames[photo.uid],
                      formatPhotoTime(context, photo.createdAt),
                    ].join(' · '),
                    onDelete: mine ? () => _delete(photo) : null,
                  ),
                ),
                _Chrome(
                  visible: _chromeVisible,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_photos.length > 1)
                        _PageDots(count: _photos.length, index: _index),
                      if (!mine && myUid != null)
                        _ReactionBar(
                          selected: _myReaction(photo, myUid),
                          onTap: (e) => _toggleReaction(photo, e),
                        )
                      else if (partnerReaction != null)
                        _ReactionPill(
                          text: l.photoPartnerReacted(
                            pair?.memberNames[partnerUid] ??
                                l.todayPartnerFallbackName,
                            partnerReaction,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades the viewer's top/bottom overlays in and out (tap to toggle).
class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.visible,
    required this.alignment,
    required this.child,
  });

  final bool visible;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final top = alignment == Alignment.topCenter;
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: const [Color(0x99000000), Color(0x00000000)],
              ),
            ),
            child: SafeArea(
              top: top,
              bottom: !top,
              child: Padding(
                padding: EdgeInsets.only(
                  top: top ? 4 : 24,
                  bottom: top ? 24 : 16,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.goalIcon,
    required this.title,
    required this.subtitle,
    required this.onDelete,
  });

  final String goalIcon;
  final String title;
  final String subtitle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton(
          tooltip: l.photoClose,
          color: Colors.white,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
        const SizedBox(width: 4),
        Text(
          goalIcon,
          style: const TextStyle(fontSize: 26),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            tooltip: l.photoDelete,
            color: Colors.white,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// One photo: the thumbnail (blurred, upscaled) until the full image is
/// loaded, inside a pinch / double-tap zoom.
class _PhotoPage extends ConsumerStatefulWidget {
  const _PhotoPage({
    super.key,
    required this.photo,
    required this.onZoomChanged,
  });

  final GoalPhoto photo;
  final ValueChanged<bool> onZoomChanged;

  @override
  ConsumerState<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends ConsumerState<_PhotoPage> {
  final _transform = TransformationController();
  Offset _doubleTapAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transform.addListener(
      () => widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01),
    );
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
    } else {
      const scale = 2.5;
      final p = _doubleTapAt;
      _transform.value = Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final photo = widget.photo;
    final full = ref.watch(fullPhotoProvider(photo.id));
    final ratio = photo.width > 0 && photo.height > 0
        ? photo.width / photo.height
        : 1.0;
    final placeholder = ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Image(image: thumbnailImage(photo), fit: BoxFit.cover),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
          onDoubleTap: _toggleZoom,
          child: InteractiveViewer(
            transformationController: _transform,
            maxScale: 4,
            child: Center(
              child: AspectRatio(
                aspectRatio: ratio,
                child: switch (full) {
                  AsyncData(:final value) => Image.memory(
                    value,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    frameBuilder: (_, child, frame, sync) =>
                        sync || frame != null
                        ? child
                        : Stack(
                            fit: StackFit.expand,
                            children: [placeholder, child],
                          ),
                  ),
                  _ => placeholder,
                },
              ),
            ),
          ),
        ),
        if (full.isLoading)
          const Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
          ),
        if (full.hasError)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReactionPill(text: l.photoLoadFailed),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => ref.invalidate(fullPhotoProvider(photo.id)),
                  icon: const Icon(Icons.refresh),
                  label: Text(l.photoRetry),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({required this.selected, required this.onTap});

  final String? selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final e in photoReactions)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _ReactionButton(
            emoji: e,
            selected: selected == e,
            onTap: () => onTap(e),
          ),
        ),
    ],
  );
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Tooltip(
      message: l.photoReact(emoji),
      child: Semantics(
        button: true,
        selected: selected,
        child: AnimatedScale(
          scale: selected ? 1.15 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.elasticOut,
          child: Material(
            shape: CircleBorder(
              side: BorderSide(
                color: selected ? Colors.white : Colors.white24,
                width: 2,
              ),
            ),
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: 56,
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  );
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    ),
  );
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l.photoDeleteTitle),
      content: Text(l.photoDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.todayCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 44),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.photoDeleteConfirm),
        ),
      ],
    );
  }
}
