/// A ledger entry on the wallet. Mirrors the fields the backend phase will
/// persist in Firestore (`wallet_transactions`): id, amount, type, date,
/// status and payment method.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.method,
    required this.createdAt,
    this.note,
  });

  final String id;
  final double amount;

  /// Positive credits, negative debits. Rendered with an explicit sign.
  final TransactionType type;
  final TransactionStatus status;
  final String method;
  final DateTime createdAt;
  final String? note;
}

enum TransactionType { recharge, serviceCharge }

enum TransactionStatus { completed, pending, failed }

extension TransactionTypeLabel on TransactionType {
  String get label => switch (this) {
        TransactionType.recharge => 'RECHARGE',
        TransactionType.serviceCharge => 'SERVICE CHARGE',
      };
}

extension TransactionStatusLabel on TransactionStatus {
  String get label => switch (this) {
        TransactionStatus.completed => 'COMPLETED',
        TransactionStatus.pending => 'PENDING',
        TransactionStatus.failed => 'FAILED',
      };
}
