import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/wallet_transaction.dart';
import '../../services/service_locator.dart';
import '../../utils/formatters.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/buttons.dart';
import '../../widgets/mark_widgets.dart';
import '../../widgets/placard_label.dart';
import '../settings/settings_screen.dart';
import '../splash/splash_screen.dart';
import '../transactions/transaction_history_screen.dart';

/// The pilot's station: identity, panel statistics, and the controls to
/// reach every other surface.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.hairline),
        ),
        title: const Text(
          AppStrings.logoutConfirmTitle,
          style: TextStyle(color: AppColors.luminous, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          AppStrings.logoutConfirmBody,
          style: TextStyle(color: AppColors.dim, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.dim),
            child: const Text(AppStrings.logoutNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text(AppStrings.logoutYes),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;

    setState(() => _loggingOut = true);
    await Services.auth.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) return const SizedBox.shrink();
    final wallet = Services.wallet;
    final totalRecharged = wallet.transactions
        .where((t) => t.type == TransactionType.recharge)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.luminous,
        elevation: 0,
        title: const Text(
          AppStrings.profileTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                AvatarRing(user: user, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: AppColors.luminous,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppColors.dim, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      PlacardLabel(
                        '${AppStrings.memberSince}  ${Formatters.monthYear(user.createdAt)}',
                        size: 9,
                        spacing: 1.4,
                        color: AppColors.faint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                StatCell(label: AppStrings.walletBalance, value: Formatters.currency(wallet.balance), accent: true),
                const SizedBox(width: 12),
                StatCell(
                  label: AppStrings.totalRecharged,
                  value: 'PKR ${Formatters.amount(totalRecharged)}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const PlacardLabel('PANEL CONTROLS', size: 10, spacing: 2, color: AppColors.faint),
            const SizedBox(height: 10),
            _menuTile(
              icon: Icons.speed_rounded,
              title: AppStrings.menuRecharge,
              onTap: () => Navigator.of(context)
                  .pushNamed(Routes.recharge)
                  .then((_) => setState(() {})),
            ),
            _menuTile(
              icon: Icons.receipt_long_rounded,
              title: AppStrings.menuHistory,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen()),
              ),
            ),
            _menuTile(
              icon: Icons.tune_rounded,
              title: AppStrings.menuSettings,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            _menuTile(
              icon: Icons.info_outline_rounded,
              title: AppStrings.menuAbout,
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.hairline),
                  ),
                  title: const Text(
                    AppStrings.menuAbout,
                    style: TextStyle(color: AppColors.luminous, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  content: const Text(
                    AppStrings.aboutBody,
                    style: TextStyle(color: AppColors.dim, fontSize: 13, height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: AppColors.radium),
                      child: const Text('CLOSE'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _loggingOut
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.radium,
                      ),
                    ),
                  )
                : SecondaryButton(
                    label: AppStrings.logout,
                    icon: Icons.logout_rounded,
                    onPressed: _confirmLogout,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.radium),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.luminous,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}
