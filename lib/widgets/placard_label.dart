import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Instrument placard: a terse, letter-spaced uppercase caption used for
/// every label, like the text stencilled beneath a gauge.
class PlacardLabel extends StatelessWidget {
  const PlacardLabel(
    this.text, {
    super.key,
    this.color = AppColors.dim,
    this.size = 11,
    this.spacing = 1.4,
  });

  final String text;
  final Color color;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: spacing,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A glowing status lamp: a small filled dot that says completed / pending /
/// failed / info without words.
class LampDot extends StatelessWidget {
  const LampDot(this.status, {super.key, this.size = 8});

  final WidgetStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.forStatus(status),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Lamp + placard pair used by status badges and section markers.
class LampLabel extends StatelessWidget {
  const LampLabel(this.status, this.text, {super.key, this.size = 10.5});

  final WidgetStatus status;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LampDot(status, size: size - 2),
        const SizedBox(width: 6),
        PlacardLabel(text, size: size, spacing: 1.2),
      ],
    );
  }
}
