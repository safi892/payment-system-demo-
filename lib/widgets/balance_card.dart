import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/formatters.dart';
import 'placard_label.dart';

/// The instrument face of the app: wallet balance rendered as a primary
/// reading. Luminous digits, placard captions, a LIVE lamp when current,
/// and a damped count-up when the value changes.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    this.isLive = true,
  });

  final double balance;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PlacardLabel(AppStrings.walletBalance, color: AppColors.faint),
              const Spacer(),
              LampLabel(
                isLive ? WidgetStatus.completed : WidgetStatus.idle,
                isLive ? AppStrings.live : 'SYNC',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const PlacardLabel('PKR', size: 12, spacing: 2.4, color: AppColors.dim),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                Formatters.amount(value),
                style: const TextStyle(
                  color: AppColors.luminous,
                  fontSize: 46,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.8,
                  height: 1.1,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _tickRule(),
              const SizedBox(width: 10),
              const PlacardLabel('AVAILABLE FUNDS', size: 10, spacing: 1.8, color: AppColors.faint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tickRule() {
    return Container(width: 28, height: 1, color: AppColors.hairlineBright);
  }
}

/// Two-cell readout row below the balance — the secondary instruments of
/// the panel (total recharged, transaction count).
class StatCell extends StatelessWidget {
  const StatCell({
    super.key,
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlacardLabel(label, size: 10, spacing: 1.4, color: AppColors.faint),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: accent ? AppColors.radium : AppColors.luminous,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
