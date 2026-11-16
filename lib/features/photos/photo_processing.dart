/// Turns a picked image into the two JPEGs a `GoalPhoto` is stored as: the
/// full photo (≤ [fullPhotoMaxSide]) and its thumbnail (≤ [thumbnailMaxSide]).
///
/// [processPhoto] is pure (bytes in, bytes out) so it can run in an isolate
/// via [processPhotoInBackground] and be unit-tested directly.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show compute, kIsWeb, visibleForTesting;
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
/// small enough JPEG without any private metadata (see [_reusableJpeg]),
/// which skips a lossy re-encode. Otherwise the photo is re-encoded, which
/// also strips metadata such as the GPS location. Transparent areas become
/// white.
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

  // (The JPEG decoder already applies the orientation; other formats may not.)
  final upright = _onWhite(img.bakeOrientation(decoded)..exif = img.ExifData());
  final full = _fit(upright, limits.fullMaxSide);
  final reusable = _reusableJpeg(bytes, limits) != null;
  return (
    full: reusable ? bytes : _encodeFull(full, limits),
    thumbnail: _encodeThumb(_fit(full, limits.thumbMaxSide), limits),
    width: full.width,
    height: full.height,
  );
}

/// Like [processPhoto], but lets the engine's image codec (the browser on the
/// web) decode and scale the picture, so only small images go through the
/// pure-Dart code. Used on the web, where there are no isolates and decoding
/// a photo with package:image blocks the UI for up to a second.
///
/// JPEGs with metadata go through [processPhoto], which honours their EXIF
/// orientation exactly; the web picker's output (re-encoded with a canvas)
/// has none.
@visibleForTesting
Future<ProcessedPhoto> processPhotoWithCodec(
  Uint8List bytes, {
  PhotoLimits limits = const PhotoLimits(),
}) async {
  final jpeg = _inspectJpeg(bytes);
  if (jpeg != null && !jpeg.clean) return processPhoto(bytes, limits: limits);

  if (_reusableJpeg(bytes, limits) case (:final width, :final height)) {
    final thumb = await _decodeWithCodec(bytes, limits.thumbMaxSide);
    return (
      full: bytes,
      thumbnail: _encodeThumb(thumb, limits),
      width: width,
      height: height,
    );
  }
  // Too large a JPEG, or a PNG (the web picker keeps the original format):
  // let the codec scale it down before any Dart code touches the pixels.
  final full = await _decodeWithCodec(bytes, limits.fullMaxSide);
  return (
    full: _encodeFull(full, limits),
    thumbnail: _encodeThumb(_fit(full, limits.thumbMaxSide), limits),
    width: full.width,
    height: full.height,
  );
}

/// Runs [processPhoto] off the UI thread: in an isolate on mobile, and with
/// the browser's image decoder on the web (see [processPhotoWithCodec]).
Future<ProcessedPhoto> processPhotoInBackground(Uint8List bytes) => kIsWeb
    ? processPhotoWithCodec(bytes)
    : compute(_processDefault, bytes);

ProcessedPhoto _processDefault(Uint8List bytes) => processPhoto(bytes);

/// Decodes [bytes] with the engine's codec, scaled so the long side is at
/// most [maxSide], into a package:image image on white.
Future<img.Image> _decodeWithCodec(Uint8List bytes, int maxSide) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (w, h) => math.max(w, h) <= maxSide
          ? const ui.TargetImageSize()
          : w >= h
          ? ui.TargetImageSize(width: maxSide)
          : ui.TargetImageSize(height: maxSide),
    );
    try {
      final frame = (await codec.getNextFrame()).image;
      try {
        final rgba = await frame.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        return _onWhite(
          img.Image.fromBytes(
            width: frame.width,
            height: frame.height,
            bytes: rgba!.buffer,
            bytesOffset: rgba.offsetInBytes,
            numChannels: 4,
            order: img.ChannelOrder.rgba,
          ),
        );
      } finally {
        frame.dispose();
      }
    } finally {
      codec.dispose();
    }
  } catch (e) {
    throw AppException('photo-unreadable', e);
  }
}

/// The size of [bytes] when they can be uploaded as is: a JPEG within the
/// limits that carries no metadata beyond JFIF and an ICC colour profile.
({int width, int height})? _reusableJpeg(Uint8List bytes, PhotoLimits limits) {
  final jpeg = _inspectJpeg(bytes);
  if (jpeg == null || !jpeg.clean) return null;
  if (math.max(jpeg.width, jpeg.height) > limits.fullMaxSide) return null;
  if (bytes.length > limits.maxFullBytes) return null;
  return (width: jpeg.width, height: jpeg.height);
}

/// Walks the segments of a JPEG. Returns its frame size and whether it is
/// free of metadata that could be private: any APPn segment except an APP0
/// JFIF header and APP2 ICC profile (EXIF and XMP may hold the GPS location,
/// IPTC the author, APP2 MPF further images), and comments. Null when
/// [bytes] are not a well-formed JPEG.
({int width, int height, bool clean})? _inspectJpeg(Uint8List bytes) {
  final n = bytes.length;
  if (n < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var clean = true;
  int? width, height;
  var i = 2;
  while (true) {
    if (i + 1 >= n || bytes[i] != 0xFF) return null;
    while (i + 1 < n && bytes[i + 1] == 0xFF) {
      i++; // Fill bytes.
    }
    if (i + 1 >= n) return null;
    final marker = bytes[i + 1];
    i += 2;
    if (marker == 0xD9) break; // EOI
    // Markers without a payload: TEM and RST0-7.
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
    if (i + 1 >= n) return null;
    final length = bytes[i] << 8 | bytes[i + 1];
    if (length < 2 || i + length > n) return null;
    final payload = Uint8List.sublistView(bytes, i + 2, i + length);
    final isSof =
        marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8;
    if (isSof && payload.length >= 5) {
      height = payload[1] << 8 | payload[2];
      width = payload[3] << 8 | payload[4];
    } else if (marker == 0xFE) {
      clean = false; // COM
    } else if (marker >= 0xE0 && marker <= 0xEF) {
      final allowed =
          (marker == 0xE0 && _startsWith(payload, 'JFIF\x00')) ||
          (marker == 0xE2 && _startsWith(payload, 'ICC_PROFILE\x00'));
      if (!allowed) clean = false;
    }
    i += length;
    if (marker == 0xDA) {
      // Skip the entropy-coded scan up to the next real marker (0xFF that
      // is not stuffing (FF 00) nor a restart marker).
      while (i + 1 < n &&
          !(bytes[i] == 0xFF &&
              bytes[i + 1] != 0x00 &&
              (bytes[i + 1] < 0xD0 || bytes[i + 1] > 0xD7))) {
        i++;
      }
    }
  }
  if (width == null || height == null || width == 0 || height == 0) {
    return null;
  }
  return (width: width, height: height, clean: clean);
}

bool _startsWith(Uint8List bytes, String ascii) {
  if (bytes.length < ascii.length) return false;
  for (var i = 0; i < ascii.length; i++) {
    if (bytes[i] != ascii.codeUnitAt(i)) return false;
  }
  return true;
}

/// [image] composited onto white: JPEG has no alpha, and its encoder would
/// turn transparent pixels black.
img.Image _onWhite(img.Image image) {
  if (!image.hasAlpha) return image;
  final white = img.Image(width: image.width, height: image.height)
    ..clear(img.ColorRgb8(255, 255, 255));
  return img.compositeImage(white, image);
}

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

Uint8List _encodeFull(img.Image image, PhotoLimits limits) => _encodeWithin(
  image,
  limits.maxFullBytes,
  PhotoLimits.fullQuality,
  PhotoLimits.fullRetryQuality,
);

Uint8List _encodeThumb(img.Image image, PhotoLimits limits) => _encodeWithin(
  image,
  limits.maxThumbBytes,
  PhotoLimits.thumbQuality,
  PhotoLimits.thumbRetryQuality,
);

Uint8List _encodeWithin(img.Image image, int maxBytes, int quality, int retry) {
  final first = img.encodeJpg(image, quality: quality);
  if (first.length <= maxBytes) return first;
  final second = img.encodeJpg(image, quality: retry);
  if (second.length <= maxBytes) return second;
  throw const AppException('photo-too-large');
}
