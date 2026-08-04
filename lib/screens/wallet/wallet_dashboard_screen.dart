import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/wallet_transaction.dart';
import '../../services/service_locator.dart';
import '../../utils/formatters.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/gauge_mark.dart';
import '../../widgets/mark_widgets.dart';
import '../../widgets/placard_label.dart';
import '../../widgets/transaction_tile.dart';
import '../profile/profile_screen.dart';
import '../splash/splash_screen.dart';
import '../transactions/transaction_history_screen.dart';

/// The primary instrument: balance readout, supporting stats, recharge
/// action and recent activity. Reads live from the wallet service.
class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  bool _syncing = false;
  String? _syncError;

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final wallet = Services.wallet;
    final recent = wallet.transactions.take(3).toList();
    final totalRecharged = wallet.transactions
        .where((t) => t.type == TransactionType.recharge)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppColors.panel,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _sync,
          color: AppColors.radium,
          backgroundColor: AppColors.surfaceRaised,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList.list(
                  children: [
                    _header(user.name, user.email),
                    const SizedBox(height: 26),
                    BalanceCard(balance: wallet.balance, isLive: !_syncing),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StatCell(
                          label: AppStrings.totalRecharged,
                          value: 'PKR ${Formatters.amount(totalRecharged)}',
                          accent: true,
                        ),
                        const SizedBox(width: 12),
                        StatCell(
                          label: AppStrings.transactions,
                          value: Formatters.amount(wallet.transactions.length),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: AppStrings.rechargeButton,
                      icon: Icons.add_rounded,
                      onPressed: () async {
                        await Navigator.of(context)
                            .pushNamed(Routes.recharge);
                        if (mounted) setState(() {});
                      },
                    ),
                    if (_syncError != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(
                        message: _syncError!,
                        onDismiss: () => setState(() => _syncError = null),
                      ),
                    ],
                    const SizedBox(height: 30),
                    SectionHeader(
                      title: AppStrings.recentActivity,
                      actionLabel: AppStrings.viewAll,
                      onAction: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) =>
                                  const TransactionHistoryScreen())),
                    ),
                    const SizedBox(height: 4),
                    for (final t in recent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TransactionTile(transaction: t),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String name, String email) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? AppStrings.goodMorning
        : hour < 17
            ? AppStrings.goodAfternoon
            : AppStrings.goodEvening;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const GaugeMark(size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: const TextStyle(
                  color: AppColors.luminous,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              PlacardLabel(Formatters.date(DateTime.now()), size: 9.5, spacing: 1.6),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Services.auth.currentUser == null
              ? const SizedBox.shrink()
              : AvatarRing(user: Services.auth.currentUser!, size: 42),
        ),
      ],
    );
  }

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    try {
      await Services.wallet.refresh();
      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.refreshed,
              style: const TextStyle(color: AppColors.luminous, fontSize: 12.5),
            ),
            backgroundColor: AppColors.surfaceRaised,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.hairlineBright),
            ),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          ),
        );
    } on AppException {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _syncError = AppStrings.refreshFailed;
      });
    }
  }
}
