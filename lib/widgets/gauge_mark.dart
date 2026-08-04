import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The app's mark: a flight-instrument gauge. A hairline ring holds an
/// arc, a radium needle sweeps it, and a center dot anchors the reading.
/// `needle` is in degrees, 0 = straight right, positive = clockwise.
class GaugeMark extends StatelessWidget {
  const GaugeMark({super.key, this.size = 28, this.needle = 45});

  final double size;
  final double needle;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GaugePainter(needle: needle)),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.needle});

  final double needle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.045
      ..color = AppColors.hairlineBright;
    canvas.drawCircle(center, radius - ring.strokeWidth / 2, ring);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.round
      ..color = AppColors.radium;
    const sweep = 240.0;
    const start = -120.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.62),
      (start + 90) * math.pi / 180,
      sweep * math.pi / 180,
      false,
      arc,
    );

    final needlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.05
      ..strokeCap = StrokeCap.round
      ..color = AppColors.luminous;
    final angle = (needle + 90) * math.pi / 180;
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.55,
      needlePaint,
    );

    canvas.drawCircle(
      center,
      size.shortestSide * 0.06,
      Paint()..color = AppColors.radium,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.needle != needle;
}
