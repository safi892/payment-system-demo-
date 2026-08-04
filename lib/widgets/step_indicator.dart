import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'placard_label.dart';

/// State of one payment-simulation step.
enum StepPhase { pending, working, done }

/// Damped step indicator used during the payment simulation: each stage
/// shows pending → working → completed as a lamp + placard row.
class StepRow extends StatelessWidget {
  const StepRow({super.key, required this.label, required this.state});

  final String label;
  final StepPhase state;

  @override
  Widget build(BuildContext context) {
    final status = switch (state) {
      StepPhase.pending => WidgetStatus.idle,
      StepPhase.working => WidgetStatus.pending,
      StepPhase.done => WidgetStatus.completed,
    };
    return Row(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: state == StepPhase.pending ? 0.45 : 1,
          child: LampDot(status),
        ),
        const SizedBox(width: 12),
        PlacardLabel(
          label,
          size: 11.5,
          spacing: 1.6,
          color: state == StepPhase.pending ? AppColors.faint : AppColors.luminous,
        ),
      ],
    );
  }
}
