import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/wallet_transaction.dart';
import '../../services/service_locator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/placard_label.dart';
import '../../widgets/transaction_tile.dart';

/// Full ledger: filter chips (all / recharge / charges), a newest-oldest
/// sort toggle, and pull-to-refresh that simulates a server sync.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TransactionType? _filter;
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Services.wallet,
      builder: (context, _) {
        final rows = Services.wallet.filter(
          type: _filter,
          newestFirst: _newestFirst,
        );

        return Scaffold(
          backgroundColor: AppColors.panel,
          appBar: AppBar(
            backgroundColor: AppColors.panel,
            foregroundColor: AppColors.luminous,
            elevation: 0,
            title: const Text(
              AppStrings.historyTitle,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _filterChip(AppStrings.all, null),
                            _filterChip(
                              AppStrings.rechargeFilter,
                              TransactionType.recharge,
                            ),
                            _filterChip(
                              AppStrings.chargeFilter,
                              TransactionType.serviceCharge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _sortButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => Services.wallet.refresh(),
                    color: AppColors.radium,
                    backgroundColor: AppColors.surfaceRaised,
                    child: rows.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                title: AppStrings.emptyTitle,
                                body: AppStrings.emptyBody,
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                TransactionTile(transaction: rows[index]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, TransactionType? type) {
    final selected = _filter == type;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => setState(() => _filter = type),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.radiumSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.radium : AppColors.hairline,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.radium : AppColors.dim,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortButton() {
    return Semantics(
      button: true,
      label: 'Sort ${_newestFirst ? 'newest' : 'oldest'} first',
      child: InkWell(
        onTap: () => setState(() => _newestFirst = !_newestFirst),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Icon(
                _newestFirst
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 14,
                color: AppColors.radium,
              ),
              const SizedBox(width: 6),
              PlacardLabel(
                _newestFirst ? AppStrings.sortNewest : AppStrings.sortOldest,
                size: 9,
                spacing: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
