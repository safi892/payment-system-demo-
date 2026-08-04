import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/app_user.dart';
import 'gauge_mark.dart';
import 'placard_label.dart';

/// Error banner rendered for service-level failures (login, register,
/// sync). Hairline red cell with a red lamp — never a toast.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          const LampDot(WidgetStatus.failed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.luminous,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.dim),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}

/// Avatar ring: initials inside a hairline circle, like the owner placard
/// on an instrument panel.
class AvatarRing extends StatelessWidget {
  const AvatarRing({super.key, required this.user, this.size = 40});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairlineBright),
        color: AppColors.surfaceRaised,
      ),
      child: Text(
        user.initials,
        style: TextStyle(
          color: AppColors.radium,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Compact brand lockup: gauge mark + "WALLET" placard.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GaugeMark(size: size),
        const SizedBox(width: 10),
        const PlacardLabel(AppStrings.appName, size: 13, spacing: 3, color: AppColors.luminous),
      ],
    );
  }
}
