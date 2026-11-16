import 'dart:typed_data';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'photo_providers.dart';

enum PhotoSource { camera, gallery }

/// Picks one image and returns its bytes, or null when cancelled.
abstract interface class PhotoPicker {
  Future<Uint8List?> pick(PhotoSource source);
}

/// [PhotoPicker] backed by image_picker. The plugin already resizes to
/// [fullPhotoMaxSide] and re-compresses (natively on Android, with a canvas
/// on the web), so the bytes are usually upload-ready.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        PhotoSource.camera => ImageSource.camera,
        PhotoSource.gallery => ImageSource.gallery,
      },
      maxWidth: fullPhotoMaxSide.toDouble(),
      maxHeight: fullPhotoMaxSide.toDouble(),
      imageQuality: 80,
      requestFullMetadata: false,
    );
    return file?.readAsBytes();
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
  void showError(Object e) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(errorMessage(l, e))));

  // Read everything up front: the card may be rebuilt away while waiting.
  final uploads = ref.read(photoUploadsProvider.notifier);
  final picker = ref.read(photoPickerProvider);
  if (uploads.limitReached) return showError(const AppException('photo-limit'));

  final source = await showPhotoSourceSheet(context, goal: goal);
  if (source == null) return;

  final Uint8List? bytes;
  try {
    bytes = await picker.pick(source);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.photoErrPicker)));
    return;
  }
  if (bytes == null) return;

  try {
    await uploads.upload(goal.id, bytes);
    HapticFeedback.mediumImpact();
  } catch (e) {
    showError(e);
  }
}

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
