import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'photo_providers.dart';

enum PhotoSource { camera, gallery }

/// The goal and day a photo is being taken for.
typedef PhotoTarget = ({String goalId, String day});

/// A photo recovered by [PhotoPicker.retrieveLost].
typedef LostPhoto = ({PhotoTarget target, Uint8List bytes});

/// Whether the system may kill the app while the camera or gallery is open,
/// so the picked photo only comes back on the next start (Android).
bool get pickerMayLoseData =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

abstract interface class PhotoPicker {
  /// Picks one image for [target] and returns its bytes, or null when
  /// cancelled.
  Future<Uint8List?> pick(PhotoSource source, PhotoTarget target);

  /// The photo of a [pick] whose app was killed before it returned, with
  /// the target it was picked for; null when there is none. Forgets it, so
  /// it is returned only once. Only call when [pickerMayLoseData].
  Future<LostPhoto?> retrieveLost();
}

/// [PhotoPicker] backed by image_picker. The plugin resizes to
/// [fullPhotoMaxSide] (natively on Android, with a canvas on the web); the
/// high [imageQuality] keeps that step near-lossless, so our own re-encode
/// (which also strips metadata) is the only lossy one.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const imageQuality = 95;

  /// SharedPreferences key of the [PhotoTarget] of the pick in progress.
  @visibleForTesting
  static const pendingTargetKey = 'photos.pendingTarget';

  @override
  Future<Uint8List?> pick(PhotoSource source, PhotoTarget target) async {
    final prefs = pickerMayLoseData
        ? await SharedPreferences.getInstance()
        : null;
    await prefs?.setString(
      pendingTargetKey,
      jsonEncode({'goalId': target.goalId, 'day': target.day}),
    );
    try {
      final file = await _picker.pickImage(
        source: switch (source) {
          PhotoSource.camera => ImageSource.camera,
          PhotoSource.gallery => ImageSource.gallery,
        },
        maxWidth: fullPhotoMaxSide.toDouble(),
        maxHeight: fullPhotoMaxSide.toDouble(),
        imageQuality: imageQuality,
        requestFullMetadata: false,
      );
      return await file?.readAsBytes();
    } finally {
      await prefs?.remove(pendingTargetKey);
    }
  }

  @override
  Future<LostPhoto?> retrieveLost() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Always asked, so the plugin's copy is consumed even without a target.
      final file = (await _picker.retrieveLostData()).file;
      final target = _parseTarget(prefs.getString(pendingTargetKey));
      if (file == null || target == null) return null;
      return (target: target, bytes: await file.readAsBytes());
    } finally {
      await prefs.remove(pendingTargetKey);
    }
  }

  static PhotoTarget? _parseTarget(String? json) {
    if (json == null) return null;
    try {
      return switch (jsonDecode(json)) {
        {'goalId': final String goalId, 'day': final String day} => (
          goalId: goalId,
          day: day,
        ),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }
}

/// Overridden in widget tests with a fake that returns fixed bytes.
final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);

/// Asks for camera or gallery.
Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  required GoalDef goal,
}) {
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  return showModalBottomSheet<PhotoSource>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      goal.icon,
                      style: const TextStyle(fontSize: 28),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.photoAdd,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            goal.title(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                label: l.photoTakePhoto,
                source: PhotoSource.camera,
              ),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: l.photoChooseFromGallery,
                source: PhotoSource.gallery,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.source,
  });

  final IconData icon;
  final String label;
  final PhotoSource source;

  @override
  Widget build(BuildContext context) => ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    leading: Icon(icon),
    title: Text(label),
    onTap: () => Navigator.of(context).pop(source),
  );
}

/// The full "add a photo to [goal]" flow: source sheet, picker, processing
/// and upload. Errors are shown in a snackbar.
Future<void> addGoalPhoto(
  BuildContext context,
  WidgetRef ref,
  GoalDef goal,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Read everything up front: the card may be rebuilt away while waiting.
  final uploads = ref.read(photoUploadsProvider.notifier);
  final picker = ref.read(photoPickerProvider);
  final target = (goalId: goal.id, day: ref.read(todayKeyProvider));
  if (uploads.limitReached) {
    return _showError(messenger, l, const AppException('photo-limit'));
  }

  final source = await showPhotoSourceSheet(context, goal: goal);
  if (source == null) return;

  final Uint8List? bytes;
  try {
    bytes = await picker.pick(source, target);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.photoErrPicker)));
    return;
  }
  if (bytes == null) return;
  await _upload(messenger, l, uploads, target.goalId, bytes);
}

/// Uploads a photo picked in a previous run of the app that the system
/// killed while the camera was open (see [PhotoPicker.retrieveLost]), if it
/// was taken today. Call once on startup, when [pickerMayLoseData].
Future<void> recoverLostGoalPhoto(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final uploads = ref.read(photoUploadsProvider.notifier);
  final picker = ref.read(photoPickerProvider);
  final today = ref.read(todayKeyProvider);

  final LostPhoto? lost;
  try {
    lost = await picker.retrieveLost();
  } catch (_) {
    return; // Nothing we can do; the photo is gone either way.
  }
  if (lost == null || lost.target.day != today) return;
  if (uploads.limitReached) {
    return _showError(messenger, l, const AppException('photo-limit'));
  }
  await _upload(messenger, l, uploads, lost.target.goalId, lost.bytes);
}

Future<void> _upload(
  ScaffoldMessengerState messenger,
  AppLocalizations l,
  PhotoUploads uploads,
  String goalId,
  Uint8List bytes,
) async {
  try {
    await uploads.upload(goalId, bytes);
    HapticFeedback.mediumImpact();
  } catch (e) {
    _showError(messenger, l, e);
  }
}

void _showError(
  ScaffoldMessengerState messenger,
  AppLocalizations l,
  Object e,
) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(errorMessage(l, e))));

/// 📷 button at the end of a goal card's controls; shows a spinner while a
/// photo for this goal is uploading.
class GoalPhotoButton extends ConsumerWidget {
  const GoalPhotoButton({super.key, required this.goal, required this.title});

  final GoalDef goal;

  /// Localized goal title (for the tooltip).
  final String title;

  static const width = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final uploading = ref.watch(
      photoUploadsProvider.select((s) => s.contains(goal.id)),
    );
    return SizedBox(
      width: width,
      height: 48,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: uploading
            ? Semantics(
                key: const ValueKey('uploading'),
                label: l.photoUploading,
                liveRegion: true,
                child: Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  ),
                ),
              )
            : IconButton(
                key: const ValueKey('camera'),
                tooltip: l.photoAddFor(title),
                constraints: const BoxConstraints.tightFor(
                  width: width,
                  height: 48,
                ),
                color: scheme.onSurfaceVariant,
                onPressed: () => addGoalPhoto(context, ref, goal),
                icon: const Icon(Icons.photo_camera_outlined),
              ),
      ),
    );
  }
}
