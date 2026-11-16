import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/default_goals.dart';

/// Placeholder "photos" for the demo partner in the in-memory backend.
///
/// The images are drawn in pure Dart with `package:image`: a soft diagonal
/// gradient in a warm color with a simple motif matching the goal (a plate
/// of veggies, a glass of water, an open book, a dumbbell). No text, no
/// assets, fully deterministic.
///
/// JPEG encoding in pure Dart is the slow part, so the images are smaller
/// than real uploads ([demoFullWidth] instead of `fullPhotoMaxSide`) and
/// each motif is rendered once per process and then shared by every demo
/// photo that uses it.

/// Size of the demo full image (4:5 portrait, like a phone photo crop).
const demoFullWidth = 600;
const demoFullHeight = 750;

/// Size of the demo thumbnail.
const demoThumbWidth = 240;
const demoThumbHeight = 300;

/// What a demo photo shows.
enum DemoMotif { plate, glass, book, dumbbell }

/// The motif that suits [goalId] (a plate for anything food related).
DemoMotif demoMotifForGoal(String goalId) => switch (goalId) {
  GoalIds.water || GoalIds.noSugaryDrinks => DemoMotif.glass,
  GoalIds.reading || GoalIds.socialMedia => DemoMotif.book,
  GoalIds.workouts || GoalIds.steps => DemoMotif.dumbbell,
  _ => DemoMotif.plate,
};

/// Encoded JPEGs of one demo photo.
class DemoPhotoImage {
  const DemoPhotoImage({required this.full, required this.thumbnail});

  final Uint8List full;
  final Uint8List thumbnail;
  int get width => demoFullWidth;
  int get height => demoFullHeight;
}

final _cache = <DemoMotif, DemoPhotoImage>{};

/// The (cached) demo photo for [motif].
DemoPhotoImage demoPhoto(DemoMotif motif) => _cache[motif] ??= DemoPhotoImage(
  full: _encode(motif, demoFullWidth, demoFullHeight, quality: 80),
  thumbnail: _encode(motif, demoThumbWidth, demoThumbHeight, quality: 75),
);

Uint8List _encode(DemoMotif motif, int w, int h, {required int quality}) {
  final canvas = _render(motif, w, h);
  return img.encodeJpg(
    img.Image.fromBytes(
      width: w,
      height: h,
      bytes: canvas.rgb.buffer,
      numChannels: 3,
    ),
    quality: quality,
  );
}

// ------------------------------------------------------------ Rendering

/// Gradient colors (top-left, bottom-right) per motif: distinct and warm.
const _palette = {
  DemoMotif.plate: (0xFFD8B4, 0xF29E8E), // peach -> coral
  DemoMotif.glass: (0xFFE6C7, 0xF5B971), // cream -> apricot
  DemoMotif.book: (0xF9D5D3, 0xD99AAE), // blush -> dusty rose
  DemoMotif.dumbbell: (0xFCE38A, 0xE8876B), // butter -> terracotta
};

_Painter _render(DemoMotif motif, int w, int h) {
  final (from, to) = _palette[motif]!;
  final p = _Painter(w, h)..gradient(from, to);
  switch (motif) {
    case DemoMotif.plate:
      _plate(p);
    case DemoMotif.glass:
      _glass(p);
    case DemoMotif.book:
      _book(p);
    case DemoMotif.dumbbell:
      _dumbbell(p);
  }
  return p;
}

/// A tiny anti-aliased rasterizer over an RGB buffer.
///
/// `package:image`'s drawing functions go through per-pixel color objects
/// and are ~10x slower than this, which matters at app start. Shapes are
/// described by signed distance functions, which gives anti-aliasing and
/// soft (blurred) edges for shadows for free.
///
/// Coordinates are in units of the image width: x in 0..1, y in 0..1.25
/// (the height of a 4:5 image), so every size renders the same picture.
class _Painter {
  _Painter(this.w, this.h) : s = w.toDouble(), rgb = Uint8List(w * h * 3);

  final int w, h;
  final double s;
  final Uint8List rgb;

  /// An ARGB color.
  static int rgba(int rgb, [int a = 255]) => (a << 24) | rgb;

  /// Fills the image with a diagonal gradient from [from] to [to] plus a
  /// soft light spot in the upper-left.
  void gradient(int from, int to) {
    final r0 = (from >> 16) & 0xFF, g0 = (from >> 8) & 0xFF, b0 = from & 0xFF;
    final dr = ((to >> 16) & 0xFF) - r0;
    final dg = ((to >> 8) & 0xFF) - g0;
    final db = (to & 0xFF) - b0;
    final lx = w * 0.25, ly = h * 0.2, lr2 = w * w * 0.81;
    var i = 0;
    for (var y = 0; y < h; y++) {
      final ty = 0.65 * y / h, dy2 = (y - ly) * (y - ly);
      for (var x = 0; x < w; x++) {
        final t = 0.35 * x / w + ty;
        final dx = x - lx;
        // Quadratic falloff: cheaper than a true radial one, looks the same.
        final d2 = (dx * dx + dy2) / lr2;
        final light = d2 < 1 ? (1 - d2) * 0.18 : 0.0;
        final r = r0 + dr * t, g = g0 + dg * t, b = b0 + db * t;
        rgb[i] = (r + (255 - r) * light).toInt();
        rgb[i + 1] = (g + (255 - g) * light).toInt();
        rgb[i + 2] = (b + (255 - b) * light).toInt();
        i += 3;
      }
    }
  }

  /// Blends [color] into every pixel of the box ([x1],[y1])..([x2],[y2])
  /// (unit coordinates) by the coverage that [sdf] gives for the pixel
  /// center. [sdf] returns the signed distance in pixels (negative inside).
  /// [soft] (unit) widens the edge into a blur.
  void _fill(
    double x1,
    double y1,
    double x2,
    double y2,
    int color,
    double soft,
    double Function(double px, double py) sdf,
  ) {
    final edge = max(1.0, soft * s);
    final pad = edge;
    final xa = max(0, (x1 * s - pad).floor());
    final ya = max(0, (y1 * s - pad).floor());
    final xb = min(w - 1, (x2 * s + pad).ceil());
    final yb = min(h - 1, (y2 * s + pad).ceil());
    final alpha = ((color >> 24) & 0xFF) / 255;
    final opaque = alpha == 1;
    final r = (color >> 16) & 0xFF, g = (color >> 8) & 0xFF, b = color & 0xFF;
    for (var y = ya; y <= yb; y++) {
      var i = (y * w + xa) * 3;
      for (var x = xa; x <= xb; x++, i += 3) {
        final cov = 0.5 - sdf(x + 0.5, y + 0.5) / edge;
        if (cov <= 0) continue;
        if (cov >= 1 && opaque) {
          rgb[i] = r;
          rgb[i + 1] = g;
          rgb[i + 2] = b;
          continue;
        }
        final k = cov >= 1 ? alpha : cov * alpha;
        rgb[i] += ((r - rgb[i]) * k).round();
        rgb[i + 1] += ((g - rgb[i + 1]) * k).round();
        rgb[i + 2] += ((b - rgb[i + 2]) * k).round();
      }
    }
  }

  void circle(double x, double y, double r, int color, {double soft = 0}) {
    final cx = x * s, cy = y * s, rr = r * s;
    _fill(x - r, y - r, x + r, y + r, color, soft, (px, py) {
      final dx = px - cx, dy = py - cy;
      return sqrt(dx * dx + dy * dy) - rr;
    });
  }

  void rect(
    double x1,
    double y1,
    double x2,
    double y2,
    int color, {
    double radius = 0,
    double soft = 0,
  }) {
    final cx = (x1 + x2) / 2 * s, cy = (y1 + y2) / 2 * s;
    final rr = radius * s;
    final hx = (x2 - x1) / 2 * s - rr, hy = (y2 - y1) / 2 * s - rr;
    _fill(x1, y1, x2, y2, color, soft, (px, py) {
      final qx = (px - cx).abs() - hx, qy = (py - cy).abs() - hy;
      final ox = max(qx, 0.0), oy = max(qy, 0.0);
      return sqrt(ox * ox + oy * oy) + min(max(qx, qy), 0.0) - rr;
    });
  }

  /// A convex polygon (vertices in either winding order).
  void polygon(List<(double, double)> pts, int color) {
    final n = pts.length;
    var area = 0.0;
    for (var k = 0; k < n; k++) {
      final (ax, ay) = pts[k];
      final (bx, by) = pts[(k + 1) % n];
      area += ax * by - bx * ay;
    }
    final sign = area > 0 ? 1.0 : -1.0;
    // Edge lines as (nx, ny, c): outward unit normal and offset (pixels).
    final edges = [
      for (var k = 0; k < n; k++)
        () {
          final (ax, ay) = pts[k];
          final (bx, by) = pts[(k + 1) % n];
          final ex = (bx - ax) * s, ey = (by - ay) * s;
          final len = sqrt(ex * ex + ey * ey);
          final nx = sign * ey / len, ny = -sign * ex / len;
          return (nx, ny, nx * ax * s + ny * ay * s);
        }(),
    ];
    final xs = pts.map((p) => p.$1), ys = pts.map((p) => p.$2);
    _fill(
      xs.reduce(min),
      ys.reduce(min),
      xs.reduce(max),
      ys.reduce(max),
      color,
      0,
      (px, py) {
        var d = double.negativeInfinity;
        for (final (nx, ny, c) in edges) {
          d = max(d, nx * px + ny * py - c);
        }
        return d;
      },
    );
  }
}

const _cream = 0xFFFBF4;
const _shade = 0xEFE4D6;

/// Translucent warm brown used for soft drop shadows.
final _shadow = _Painter.rgba(0x5A2E1E, 60);

void _plate(_Painter p) {
  const cx = 0.5, cy = 0.66;
  p
    ..circle(cx + 0.015, cy + 0.03, 0.36, _shadow, soft: 0.06)
    ..circle(cx, cy, 0.36, _Painter.rgba(_cream))
    ..circle(cx, cy, 0.27, _Painter.rgba(_shade))
    ..circle(cx, cy, 0.255, _Painter.rgba(_cream));
  // Salad: leaves, cherry tomatoes and a slice of yellow pepper.
  const leaves = [
    (0.42, 0.60, 0.075),
    (0.53, 0.57, 0.08),
    (0.60, 0.66, 0.07),
    (0.45, 0.71, 0.07),
    (0.54, 0.73, 0.065),
  ];
  for (final (i, (x, y, r)) in leaves.indexed) {
    p.circle(x, y, r, _Painter.rgba(i.isEven ? 0x7FB069 : 0x5E9A4C));
  }
  for (final (x, y) in const [(0.47, 0.64), (0.58, 0.61), (0.52, 0.68)]) {
    p
      ..circle(x + 0.004, y + 0.006, 0.032, _shadow, soft: 0.012)
      ..circle(x, y, 0.032, _Painter.rgba(0xE4572E))
      ..circle(x - 0.009, y - 0.01, 0.009, _Painter.rgba(0xFFFFFF, 150));
  }
  p.circle(0.40, 0.67, 0.035, _Painter.rgba(0xF4C95D));
  // Fork on the side: handle, head and three tines.
  final silver = _Painter.rgba(0xFFFFFF, 215);
  p
    ..rect(0.072, 0.56, 0.098, 0.95, silver, radius: 0.012)
    ..rect(0.055, 0.49, 0.115, 0.565, silver, radius: 0.02);
  for (var k = 0; k < 3; k++) {
    final x = 0.058 + k * 0.022;
    p.rect(x, 0.38, x + 0.011, 0.51, silver, radius: 0.005);
  }
}

void _glass(_Painter p) {
  // Shadow, glass body (tapered), water, rim and a highlight.
  p
    ..rect(0.29, 1.03, 0.71, 1.08, _shadow, radius: 0.025, soft: 0.04)
    ..polygon(const [
      (0.27, 0.34),
      (0.73, 0.34),
      (0.67, 1.05),
      (0.33, 1.05),
    ], _Painter.rgba(0xFFFFFF, 120))
    ..polygon(const [
      (0.29, 0.52),
      (0.71, 0.52),
      (0.665, 1.03),
      (0.335, 1.03),
    ], _Painter.rgba(0x8EC5E8, 210))
    ..rect(0.29, 0.515, 0.71, 0.54, _Painter.rgba(0xC4E3F5, 230), radius: 0.01)
    ..rect(
      0.265,
      0.335,
      0.735,
      0.347,
      _Painter.rgba(0xFFFFFF, 230),
      radius: 0.006,
    )
    ..polygon(const [
      (0.32, 0.40),
      (0.345, 0.40),
      (0.385, 0.98),
      (0.36, 0.98),
    ], _Painter.rgba(0xFFFFFF, 110));
  // A few bubbles and a lemon slice on the rim.
  for (final (x, y, r) in const [
    (0.55, 0.85, 0.012),
    (0.60, 0.72, 0.009),
    (0.48, 0.64, 0.01),
  ]) {
    p.circle(x, y, r, _Painter.rgba(0xFFFFFF, 170));
  }
  p
    ..circle(0.70, 0.36, 0.085, _Painter.rgba(0xF7D046))
    ..circle(0.70, 0.36, 0.065, _Painter.rgba(0xFBE89A));
}

void _book(_Painter p) {
  // Shadow, cover, then two pages slightly fanned around the spine.
  p
    ..rect(0.12, 0.41, 0.88, 0.99, _shadow, radius: 0.03, soft: 0.06)
    ..rect(0.10, 0.38, 0.86, 0.96, _Painter.rgba(0x9C4A5A), radius: 0.03)
    ..polygon(const [
      (0.13, 0.40),
      (0.48, 0.42),
      (0.48, 0.93),
      (0.13, 0.92),
    ], _Painter.rgba(_cream))
    ..polygon(const [
      (0.48, 0.42),
      (0.83, 0.40),
      (0.83, 0.92),
      (0.48, 0.93),
    ], _Painter.rgba(0xFFF6EA))
    ..rect(0.476, 0.42, 0.484, 0.93, _Painter.rgba(0xD9C7B3));
  // Lines of "text".
  final ink = _Painter.rgba(0xC9B8A6, 200);
  for (var k = 0; k < 8; k++) {
    final y = 0.48 + k * 0.052;
    p
      ..rect(0.17, y, k == 7 ? 0.33 : 0.44, y + 0.012, ink, radius: 0.006)
      ..rect(0.52, y, k == 5 ? 0.66 : 0.79, y + 0.012, ink, radius: 0.006);
  }
  // Ribbon bookmark and a cup of tea seen from above.
  p
    ..polygon(const [
      (0.62, 0.40),
      (0.67, 0.40),
      (0.67, 1.06),
      (0.645, 1.03),
      (0.62, 1.06),
    ], _Painter.rgba(0xE07A5F))
    ..circle(0.81, 0.24, 0.09, _shadow, soft: 0.04)
    ..circle(0.80, 0.23, 0.09, _Painter.rgba(_cream))
    ..circle(0.80, 0.23, 0.07, _Painter.rgba(0xB5835A))
    ..circle(0.80, 0.23, 0.055, _Painter.rgba(0xC99A6E));
}

void _dumbbell(_Painter p) {
  const y = 0.72;
  // Soft bokeh dots for depth.
  for (final (x, y, r) in const [
    (0.80, 0.24, 0.07),
    (0.66, 0.16, 0.035),
    (0.18, 1.08, 0.05),
  ]) {
    p.circle(x, y, r, _Painter.rgba(0xFFFFFF, 70));
  }
  // Shadow, bar, then two plates per side with a highlight.
  p
    ..rect(0.12, y + 0.12, 0.92, y + 0.2, _shadow, radius: 0.04, soft: 0.06)
    ..rect(
      0.22,
      y - 0.022,
      0.78,
      y + 0.022,
      _Painter.rgba(0x8A8F98),
      radius: 0.02,
    );
  for (final side in const [-1.0, 1.0]) {
    final x = 0.5 + side * 0.26;
    p
      ..rect(
        x + side * 0.08 - 0.035,
        y - 0.12,
        x + side * 0.08 + 0.035,
        y + 0.12,
        _Painter.rgba(0x52557A),
        radius: 0.025,
      )
      ..rect(
        x - 0.055,
        y - 0.17,
        x + 0.055,
        y + 0.17,
        _Painter.rgba(0x3D405B),
        radius: 0.03,
      )
      ..rect(
        x - 0.035,
        y - 0.15,
        x - 0.015,
        y + 0.10,
        _Painter.rgba(0xFFFFFF, 50),
        radius: 0.01,
      );
  }
}
