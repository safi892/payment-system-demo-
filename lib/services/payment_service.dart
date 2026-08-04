import '../constants/app_config.dart';
import '../models/payment_result.dart';

/// Simulated PayFast gateway client.
///
/// Phase 5 replaces `recharge` with a backend call — the screen keeps
/// calling `Services.payment.recharge(amount)` and rendering a
/// [PaymentResult], which is why the UI does not change.
///
/// Deterministic demo rules (see AppConfig):
///  - any valid amount        → success
///  - 9999                    → declined by simulated gateway
///  - 8888                    → timeout before verification
class PaymentService {
  Future<PaymentResult> recharge(double amount) async {
    await Future.delayed(AppConfig.paymentLatency);

    if (amount == AppConfig.simulateDeclineAmount) {
      return PaymentResult.failure(
        status: PaymentStatus.declined,
        amount: amount,
        method: 'PayFast · Simulated',
        error: 'Card declined by issuer.',
      );
    }
    if (amount == AppConfig.simulateTimeoutAmount) {
      return PaymentResult.failure(
        status: PaymentStatus.timeout,
        amount: amount,
        method: 'PayFast · Simulated',
        error: 'Gateway did not respond in time.',
      );
    }
    return PaymentResult.success(
      transactionId: 'TXN-${_stamp()}',
      amount: amount,
      method: 'PayFast · Simulated',
    );
  }

  String _stamp() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final millis = now.millisecondsSinceEpoch % 10000;
    return '$date-$millis';
  }
}
