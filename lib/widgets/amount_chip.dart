import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/formatters.dart';
import 'placard_label.dart';

/// A selectable recharge preset. Selected chips fill with radium at low
/// opacity and gain a radium hairline — like an armed instrument control.
class AmountChip extends StatelessWidget {
  const AmountChip({
    super.key,
    required this.label,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.radium : AppColors.dim;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label ${Formatters.currency(amount)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.radiumSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.radium : AppColors.hairline,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const LampDot(WidgetStatus.completed, size: 6),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.8,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
