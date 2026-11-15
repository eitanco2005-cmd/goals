import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Circular progress indicator showing a 0..100 percentage.
///
/// Changes animate smoothly; the arc grows in reading direction (clockwise in
/// LTR, counter-clockwise in RTL). With [celebrate], reaching 100% triggers a
/// small bounce plus a confetti burst.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 96,
    this.strokeWidth = 10,
    this.color = AppColors.me,
    this.celebrate = false,
    this.semanticsLabel,
    this.labelStyle,
  });

  final int percent;
  final double size;
  final double strokeWidth;
  final Color color;
  final bool celebrate;
  final String? semanticsLabel;
  final TextStyle? labelStyle;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.14,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.14,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 75,
    ),
  ]).animate(_burst);

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate && oldWidget.percent < 100 && widget.percent >= 100) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = widget.percent >= 100;
    final color = complete ? AppColors.met : widget.color;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      child: ScaleTransition(
        scale: _scale,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.percent.clamp(0, 100) / 100),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => CustomPaint(
            painter: _RingPainter(
              progress: progress,
              color: color,
              trackColor: color.withValues(alpha: 0.15),
              strokeWidth: widget.strokeWidth,
              counterClockwise: rtl,
            ),
            foregroundPainter: _BurstPainter(_burst),
            child: SizedBox.square(
              dimension: widget.size,
              child: Center(
                child: Text(
                  '${(progress * 100).round()}%',
                  textDirection: TextDirection.ltr,
                  style:
                      widget.labelStyle ??
                      theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
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

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.counterClockwise,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool counterClockwise;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = trackColor);
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress * (counterClockwise ? -1 : 1);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.counterClockwise != counterClockwise;
}

/// Confetti dots flying outwards from the ring while [t] runs 0 -> 1.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  static const _colors = [
    AppColors.met,
    AppColors.me,
    AppColors.partner,
    Color(0xFFF2C14E),
  ];
  static const _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v == 0 || v == 1) return;
    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    final eased = Curves.easeOutCubic.transform(v);
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final angle = i * 2 * math.pi / _count + (i.isEven ? 0.12 : -0.08);
      final distance = base * (0.9 + 0.65 * eased * (i.isEven ? 1 : 0.8));
      paint.color = _colors[i % _colors.length].withValues(alpha: 1 - v);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        (i.isEven ? 4.5 : 3.2) * (1 - v * 0.6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
