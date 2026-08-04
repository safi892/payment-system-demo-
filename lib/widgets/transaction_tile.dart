import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/wallet_transaction.dart';
import '../utils/formatters.dart';
import 'placard_label.dart';

/// A ledger row: type ring on the left, placard type + meta in the middle,
/// signed amount and status lamp on the right. Reads like a cross-check
/// sweep across the panel.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount >= 0;
    final amountColor = isCredit ? AppColors.radium : AppColors.amber;
    final status = switch (transaction.status) {
      TransactionStatus.completed => WidgetStatus.completed,
      TransactionStatus.pending => WidgetStatus.pending,
      TransactionStatus.failed => WidgetStatus.failed,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairlineBright),
              color: AppColors.surfaceRaised,
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.remove_rounded,
              size: 20,
              color: AppColors.luminous,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlacardLabel(transaction.type.label, size: 10.5, color: AppColors.dim),
                const SizedBox(height: 4),
                Text(
                  '${transaction.method} · ${Formatters.shortDateTime(transaction.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.faint,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (transaction.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note!,
                    style: const TextStyle(color: AppColors.faint, fontSize: 10.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.signedAmount(transaction.amount),
                style: TextStyle(
                  color: amountColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LampDot(status, size: 6),
                  const SizedBox(width: 6),
                  PlacardLabel(transaction.status.label, size: 9, spacing: 1.1),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hairline section row: title on the left, action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.luminous,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.radium,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(0, 40),
              textStyle: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
