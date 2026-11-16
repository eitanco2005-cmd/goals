/// Turns a picked image into the two JPEGs a `GoalPhoto` is stored as: the
/// full photo (≤ [fullPhotoMaxSide]) and its thumbnail (≤ [thumbnailMaxSide]).
///
/// [processPhoto] is pure (bytes in, bytes out) so it can run in an isolate
/// via [processPhotoInBackground] and be unit-tested directly.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

import '../../data/repositories.dart';

/// The result of [processPhoto].
typedef ProcessedPhoto = ({
  Uint8List full,
  Uint8List thumbnail,
  int width,
  int height,
});

/// JPEG qualities and byte limits used by [processPhoto].
class PhotoLimits {
  const PhotoLimits({
    this.fullMaxSide = fullPhotoMaxSide,
    this.thumbMaxSide = thumbnailMaxSide,
    this.maxFullBytes = maxFullPhotoBytes,
    this.maxThumbBytes = maxThumbnailBytes,
  });

  final int fullMaxSide;
  final int thumbMaxSide;
  final int maxFullBytes;
  final int maxThumbBytes;

  static const fullQuality = 80;
  static const fullRetryQuality = 60;
  static const thumbQuality = 70;
  static const thumbRetryQuality = 50;
}

/// Decodes [bytes] (any format package:image reads), applies the EXIF
/// orientation and produces the upload-ready JPEGs.
///
/// The original bytes are reused as the full photo when they already are a
/// small enough JPEG without any metadata (e.g. what the web picker returns),
/// which skips a costly re-encode. Otherwise the photo is re-encoded, which
/// also strips metadata such as the GPS location.
///
/// Throws `AppException('photo-unreadable')` for bytes that are not an image
/// and `AppException('photo-too-large')` when even a lower quality is over
/// the limits.
ProcessedPhoto processPhoto(
  Uint8List bytes, {
  PhotoLimits limits = const PhotoLimits(),
}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes, frame: 0);
  } catch (e) {
    throw AppException('photo-unreadable', e);
  }
  if (decoded == null || decoded.width == 0 || decoded.height == 0) {
    throw const AppException('photo-unreadable');
  }

  final reusable =
      img.findFormatForData(bytes) == img.ImageFormat.jpg &&
      (img.decodeJpgExif(bytes)?.isEmpty ?? true) &&
      math.max(decoded.width, decoded.height) <= limits.fullMaxSide &&
      bytes.length <= limits.maxFullBytes;

  // (The JPEG decoder already applies the orientation; other formats may not.)
  final upright = img.bakeOrientation(decoded)..exif = img.ExifData();
  final full = _fit(upright, limits.fullMaxSide);
  final fullJpeg = reusable
      ? bytes
      : _encodeWithin(
          full,
          limits.maxFullBytes,
          PhotoLimits.fullQuality,
          PhotoLimits.fullRetryQuality,
        );
  final thumbJpeg = _encodeWithin(
    _fit(full, limits.thumbMaxSide),
    limits.maxThumbBytes,
    PhotoLimits.thumbQuality,
    PhotoLimits.thumbRetryQuality,
  );
  return (
    full: fullJpeg,
    thumbnail: thumbJpeg,
    width: full.width,
    height: full.height,
  );
}

/// Runs [processPhoto] off the UI thread (an isolate on mobile; inline on the
/// web, where isolates are not available).
Future<ProcessedPhoto> processPhotoInBackground(Uint8List bytes) =>
    compute(_processDefault, bytes);

ProcessedPhoto _processDefault(Uint8List bytes) => processPhoto(bytes);

/// [image] scaled down so its long side is at most [maxSide].
img.Image _fit(img.Image image, int maxSide) {
  if (math.max(image.width, image.height) <= maxSide) return image;
  final landscape = image.width >= image.height;
  return img.copyResize(
    image,
    width: landscape ? maxSide : null,
    height: landscape ? null : maxSide,
    interpolation: img.Interpolation.average,
  );
}

Uint8List _encodeWithin(img.Image image, int maxBytes, int quality, int retry) {
  final first = img.encodeJpg(image, quality: quality);
  if (first.length <= maxBytes) return first;
  final second = img.encodeJpg(image, quality: retry);
  if (second.length <= maxBytes) return second;
  throw const AppException('photo-too-large');
}
