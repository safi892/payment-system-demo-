/// Outcome of a simulated gateway transaction. Phase 5 replaces the
/// simulation with a backend call, but the UI contract stays identical.
class PaymentResult {
  const PaymentResult({
    required this.transactionId,
    required this.amount,
    required this.method,
    required this.status,
    this.error,
  });

  final String transactionId;
  final double amount;
  final String method;
  final PaymentStatus status;
  final String? error;

  bool get isSuccess => status == PaymentStatus.success;

  factory PaymentResult.success({
    required String transactionId,
    required double amount,
    required String method,
  }) =>
      PaymentResult(
        transactionId: transactionId,
        amount: amount,
        method: method,
        status: PaymentStatus.success,
      );

  factory PaymentResult.failure({
    required PaymentStatus status,
    required double amount,
    required String method,
    required String error,
  }) =>
      PaymentResult(
        transactionId: 'N/A',
        amount: amount,
        method: method,
        status: status,
        error: error,
      );
}

enum PaymentStatus { success, declined, timeout }
