import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_config.dart';
import '../firebase/firebase_bootstrap.dart';
import '../models/payment_result.dart';
import 'service_locator.dart';

/// Gateway client.
///
/// Dual-mode by design:
///  - Firebase configured → the payment lifecycle is persisted to
///    `payments/{reference}` (initiated → completed/failed/timed_out),
///    giving the atomic wallet credit its verification guard.
///  - Firebase unavailable → the deterministic Phase 2 simulation.
///
/// The screen keeps calling `Services.payment.recharge(amount)` and
/// rendering a [PaymentResult]; Phase 5 replaces the internals with a
/// backend call and nothing else changes.
///
/// Deterministic demo rules (see AppConfig):
///  - any valid amount        → success
///  - 9999                    → declined by simulated gateway
///  - 8888                    → timeout before verification
class PaymentService {
  Future<PaymentResult> recharge(double amount) async {
    final firebaseMode = FirebaseBootstrap.configured;
    final reference = firebaseMode ? 'TXN-${_stamp()}' : null;
    if (firebaseMode) {
      await _persistPayment(reference!, amount, status: 'initiated');
    }

    await Future.delayed(AppConfig.paymentLatency);

    if (amount == AppConfig.simulateDeclineAmount) {
      if (firebaseMode) {
        await _persistPayment(reference!, amount, status: 'failed');
      }
      return PaymentResult.failure(
        status: PaymentStatus.declined,
        amount: amount,
        method: firebaseMode ? 'PayFast · Firebase' : 'PayFast · Simulated',
        error: 'Card declined by issuer.',
      );
    }
    if (amount == AppConfig.simulateTimeoutAmount) {
      if (firebaseMode) {
        await _persistPayment(reference!, amount, status: 'timed_out');
      }
      return PaymentResult.failure(
        status: PaymentStatus.timeout,
        amount: amount,
        method: firebaseMode ? 'PayFast · Firebase' : 'PayFast · Simulated',
        error: 'Gateway did not respond in time.',
      );
    }
    return PaymentResult.success(
      transactionId: reference ?? 'TXN-${_stamp()}',
      amount: amount,
      method: firebaseMode ? 'PayFast · Firebase' : 'PayFast · Simulated',
    );
  }

  /// Writes/updates `payments/{reference}`. Best-effort: the atomic credit
  /// is what actually moves money; a missing payment doc simply makes the
  /// credit transaction a no-op.
  Future<void> _persistPayment(
    String reference,
    double amount, {
    required String status,
  }) async {
    final uid = Services.auth.currentUser?.id;
    if (uid == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final ref = FirebaseFirestore.instance
        .collection('payments')
        .doc(reference);
    try {
      final doc = await ref.get();
      if (doc.exists) {
        await ref.update({
          'status': status,
          'updatedAt': now,
          if (status == 'initiated') 'verificationStatus': 'unverified',
        });
      } else {
        await ref.set({
          'userId': uid,
          'reference': reference,
          'amount': amount,
          'currency': 'PKR',
          'method': 'PayFast',
          'status': status,
          'verificationStatus': 'unverified',
          'initiatedAt': now,
          'updatedAt': now,
        });
      }
    } on FirebaseException {
      // Offline or rules-denied: simulation semantics still apply in-app.
    }
  }

  String _stamp() {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final millis = now.millisecondsSinceEpoch % 10000;
    return '$date-$millis';
  }
}
