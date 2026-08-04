import '../models/app_user.dart';
import '../models/wallet_transaction.dart';
import '../constants/app_config.dart';

/// In-memory wallet ledger. Phase 3 swaps storage for Firestore and the
/// backend phase moves balance mutations server-side; the screen-facing
/// interface (balance / transactions / credit / refresh) stays as is.
class WalletService {
  double _balance = 0;
  final List<WalletTransaction> _transactions = [];
  bool _attached = false;

  double get balance => _balance;

  /// Newest first, as displayed.
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  /// Binds the ledger to the signed-in user. Demo users get a seeded
  /// history so the panel reads like a real instrument on first launch.
  void attach(AppUser user) {
    _attached = true;
    if (user.email == AppConfig.demoEmail && _transactions.isEmpty) {
      _seedDemoLedger();
    } else if (_transactions.isEmpty) {
      _balance = 0;
    }
  }

  bool get isAttached => _attached;

  /// Simulates a pull-to-refresh sync with the server.
  Future<void> refresh() async {
    await Future.delayed(AppConfig.syncLatency);
  }

  void credit({
    required double amount,
    required String transactionId,
    required String method,
  }) {
    _balance += amount;
    _transactions.insert(
      0,
      WalletTransaction(
        id: transactionId,
        amount: amount,
        type: TransactionType.recharge,
        status: TransactionStatus.completed,
        method: method,
        createdAt: DateTime.now(),
      ),
    );
  }

  void debit({required double amount, required String note}) {
    _balance -= amount;
    _transactions.insert(
      0,
      WalletTransaction(
        id: 'SRV-${DateTime.now().millisecondsSinceEpoch}',
        amount: -amount,
        type: TransactionType.serviceCharge,
        status: TransactionStatus.completed,
        method: 'Wallet',
        createdAt: DateTime.now(),
        note: note,
      ),
    );
  }

  /// Filtered view for the history screen.
  List<WalletTransaction> filter({TransactionType? type, bool newestFirst = true}) {
    final result = type == null
        ? List<WalletTransaction>.of(_transactions)
        : _transactions.where((t) => t.type == type).toList();
    result.sort(
      (a, b) => newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return result;
  }

  void _seedDemoLedger() {
    final now = DateTime.now();
    _balance = 8900;
    _transactions
      ..add(WalletTransaction(
        id: 'TXN-20260812-0041',
        amount: 5000,
        type: TransactionType.recharge,
        status: TransactionStatus.completed,
        method: 'PayFast',
        createdAt: now.subtract(const Duration(hours: 2)),
      ))
      ..add(WalletTransaction(
        id: 'SRV-20260811-0902',
        amount: -100,
        type: TransactionType.serviceCharge,
        status: TransactionStatus.completed,
        method: 'Wallet',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        note: 'Monthly account fee',
      ))
      ..add(WalletTransaction(
        id: 'TXN-20260808-0040',
        amount: 3000,
        type: TransactionType.recharge,
        status: TransactionStatus.completed,
        method: 'PayFast',
        createdAt: now.subtract(const Duration(days: 4, hours: 3)),
      ))
      ..add(WalletTransaction(
        id: 'TXN-20260807-0039',
        amount: 1000,
        type: TransactionType.recharge,
        status: TransactionStatus.pending,
        method: 'PayFast',
        createdAt: now.subtract(const Duration(days: 5, hours: 8)),
      ));
  }
}
