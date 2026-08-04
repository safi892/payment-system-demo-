import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../profile/profile_screen.dart';
import '../transactions/transaction_history_screen.dart';
import '../wallet/wallet_dashboard_screen.dart';

/// The panel shell: three destinations — Wallet (dashboard), History and
/// Profile — held in an IndexedStack so the dashboard keeps its state.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      body: IndexedStack(
        index: _index,
        children: const [
          WalletDashboardScreen(),
          TransactionHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.radiumSoft,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined, color: AppColors.dim),
            selectedIcon: Icon(Icons.speed_rounded, color: AppColors.radium),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: AppColors.dim),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.radium),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.dim),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.radium),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
