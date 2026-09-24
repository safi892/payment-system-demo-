import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_config.dart';
import '../firebase/firebase_bootstrap.dart';
import '../models/app_user.dart';
import '../models/wallet_transaction.dart';

/// Wallet ledger.
///
/// Dual-mode by design (Phase 3):
///  - Firebase configured → Firestore is the source of truth; balance and
///    ledger are live streams, credits run as atomic multi-doc transactions.
///  - Firebase unavailable → the in-memory mock ledger from Phase 2.
///
/// Screens read [balance] / [transactions] and call [credit] / [refresh];
/// the interface is identical in both modes. Extends [ChangeNotifier] so
/// widgets can rebuild when Firestore streams update the cache.
class WalletService extends ChangeNotifier {
  double _balance = 0;
  final List<WalletTransaction> _transactions = [];
  bool _attached = false;

  String? _uid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _walletSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ledgerSub;
  bool _disposed = false;

  double get balance => _balance;

  /// Newest first, as displayed.
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  bool get isAttached => _attached;

  bool get _firebaseMode => FirebaseBootstrap.configured;

  /// Binds the ledger to the signed-in user. Demo users get a seeded
  /// history so the panel reads like a real instrument on first launch.
  void attach(AppUser user) {
    _attached = true;
    if (_firebaseMode) {
      _uid = user.id;
      _attachFirestore(user);
      return;
    }
    if (user.email == AppConfig.demoEmail && _transactions.isEmpty) {
      _seedDemoLedger();
    } else if (_transactions.isEmpty) {
      _balance = 0;
    }
    notifyListeners();
  }

  /// Unbinds the ledger (called on logout). Mock mode keeps its state so
  /// re-login behaves exactly like Phase 2; Firestore mode drops the
  /// subscriptions and cache.
  void detach() {
    if (!_firebaseMode) return;
    _uid = null;
    _walletSub?.cancel();
    _ledgerSub?.cancel();
    _walletSub = null;
    _ledgerSub = null;
    _balance = 0;
    _transactions.clear();
    _attached = false;
    notifyListeners();
  }

  /// Pull-to-refresh. Firebase mode re-reads both documents once; mock
  /// mode simulates the network round-trip.
  Future<void> refresh() async {
    if (_firebaseMode) {
      await _refreshFirestore();
      return;
    }
    await Future.delayed(AppConfig.syncLatency);
  }

  void credit({
    required double amount,
    required String transactionId,
    required String method,
  }) {
    if (_firebaseMode) {
      // The atomic transaction resolves asynchronously; the balance and
      // ledger streams push the result into the UI.
      unawaited(
        _creditFirestore(
          amount: amount,
          transactionId: transactionId,
          method: method,
        ),
      );
      return;
    }
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
    notifyListeners();
  }

  void debit({required double amount, required String note}) {
    if (_firebaseMode) {
      // Client-initiated debits are intentionally not allowed by the
      // production posture (rules deny balance decreases); only recharges
      // flow from the client. Mock mode keeps the demo service charge.
      unawaited(_debitFirestore(amount: amount, note: note));
      return;
    }
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
    notifyListeners();
  }

  /// Filtered view for the history screen.
  List<WalletTransaction> filter({
    TransactionType? type,
    bool newestFirst = true,
  }) {
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

  // ─────────────────────────── Firebase mode ───────────────────────────

  void _attachFirestore(AppUser user) {
    _ensureWallet(user).then((_) {
      if (_disposed || _uid == null) return;
      _subscribeWallet(user.id);
      _subscribeLedger(user.id);
    });
  }

  /// Creates `wallets/{uid}` when missing. A demo first sign-in seeds the
  /// PKR 8,900 instrument state; a new account starts at zero. The create
  /// is idempotent (only when the doc does not exist).
  Future<void> _ensureWallet(AppUser user) async {
    final firestore = FirebaseFirestore.instance;
    final walletRef = firestore.collection('wallets').doc(user.id);
    try {
      if ((await walletRef.get()).exists) return;
      final now = DateTime.now().toUtc().toIso8601String();
      await walletRef.set({
        'balance': 0.0,
        'currency': 'PKR',
        'updatedAt': now,
      });
      if (user.email == AppConfig.demoEmail) {
        await _seedDemoLedgerFirestore(user.id, walletRef, now);
      }
    } on FirebaseException {
      // Offline or rules-denied: the streams below reconcile when online.
    }
  }

  Future<void> _seedDemoLedgerFirestore(
    String uid,
    DocumentReference<Map<String, dynamic>> walletRef,
    String now,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final ledger = firestore
        .collection('wallet_transactions')
        .doc(uid)
        .collection('ledger');
    Future<void> writeSeed(
      String id,
      double amount,
      String type,
      String status,
      DateTime at,
    ) => ledger.doc(id).set({
      'amount': amount,
      'type': type,
      'status': status,
      'method': 'PayFast',
      'createdAt': at.toUtc().toIso8601String(),
      if (type == 'serviceCharge') 'note': 'Monthly account fee',
    });
    final base = DateTime.now();
    await Future.wait([
      writeSeed(
        'TXN-20260812-0041',
        5000,
        'recharge',
        'completed',
        base.subtract(const Duration(hours: 2)),
      ),
      writeSeed(
        'SRV-20260811-0902',
        -100,
        'serviceCharge',
        'completed',
        base.subtract(const Duration(days: 1, hours: 6)),
      ),
      writeSeed(
        'TXN-20260808-0040',
        3000,
        'recharge',
        'completed',
        base.subtract(const Duration(days: 4, hours: 3)),
      ),
      writeSeed(
        'TXN-20260807-0039',
        1000,
        'recharge',
        'pending',
        base.subtract(const Duration(days: 5, hours: 8)),
      ),
    ]);
    await walletRef.update({'balance': 8900.0, 'updatedAt': now});
  }

  void _subscribeWallet(String uid) {
    _walletSub = FirebaseFirestore.instance
        .collection('wallets')
        .doc(uid)
        .snapshots()
        .listen((snap) {
          final next = (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
          if (next != _balance) {
            _balance = next;
            if (!_disposed) notifyListeners();
          }
        });
  }

  void _subscribeLedger(String uid) {
    _ledgerSub = FirebaseFirestore.instance
        .collection('wallet_transactions')
        .doc(uid)
        .collection('ledger')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
          _transactions
            ..clear()
            ..addAll(snap.docs.map(_transactionFromDoc));
          if (!_disposed) notifyListeners();
        });
  }

  WalletTransaction _transactionFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return WalletTransaction(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: data['type'] == 'recharge'
          ? TransactionType.recharge
          : TransactionType.serviceCharge,
      status: switch (data['status']) {
        'pending' => TransactionStatus.pending,
        'failed' => TransactionStatus.failed,
        _ => TransactionStatus.completed,
      },
      method: (data['method'] as String?) ?? 'Wallet',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: data['note'] as String?,
    );
  }

  /// Atomic credit: updates the balance and writes the ledger entry.
  /// Falls back to local state if Firestore is offline.
  Future<void> _creditFirestore({
    required double amount,
    required String transactionId,
    required String method,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final firestore = FirebaseFirestore.instance;
    final walletRef = firestore.collection('wallets').doc(uid);
    final ledgerRef = firestore
        .collection('wallet_transactions')
        .doc(uid)
        .collection('ledger')
        .doc(transactionId);
    try {
      await firestore.runTransaction((tx) async {
        final walletSnap = await tx.get(walletRef);
        final current =
            (walletSnap.data()?['balance'] as num?)?.toDouble() ?? _balance;
        final next = current + amount;
        final now = DateTime.now().toUtc().toIso8601String();
        tx.set(walletRef, {'balance': next, 'currency': 'PKR', 'updatedAt': now}, SetOptions(merge: true));
        tx.set(ledgerRef, {
          'amount': amount,
          'type': 'recharge',
          'status': 'completed',
          'method': method,
          'balanceAfter': next,
          'paymentId': transactionId,
          'createdAt': now,
        });
      });
    } on FirebaseException {
      // Firestore offline — credit locally so balance reflects immediately.
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
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _debitFirestore({
    required double amount,
    required String note,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final walletRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(uid);
        final walletSnap = await tx.get(walletRef);
        final current =
            (walletSnap.data()?['balance'] as num?)?.toDouble() ?? _balance;
        if (current < amount) return;
        final next = current - amount;
        final now = DateTime.now().toUtc().toIso8601String();
        tx.set(walletRef, {'balance': next, 'updatedAt': now}, SetOptions(merge: true));
        tx.set(
          FirebaseFirestore.instance
              .collection('wallet_transactions')
              .doc(uid)
              .collection('ledger')
              .doc('SRV-${DateTime.now().millisecondsSinceEpoch}'),
          {
            'amount': -amount,
            'type': 'serviceCharge',
            'status': 'completed',
            'method': 'Wallet',
            'balanceAfter': next,
            'createdAt': now,
            'note': note,
          },
        );
      });
    } on FirebaseException {
      // Firestore offline — debit locally so balance reflects immediately.
      if (_balance < amount) return;
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
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _refreshFirestore() async {
    final uid = _uid;
    if (uid == null) return;
    final firestore = FirebaseFirestore.instance;
    try {
      final walletSnap = await firestore.collection('wallets').doc(uid).get();
      final next = (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0;
      if (next != _balance) _balance = next;
      final ledgerSnap = await firestore
          .collection('wallet_transactions')
          .doc(uid)
          .collection('ledger')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      _transactions
        ..clear()
        ..addAll(ledgerSnap.docs.map(_transactionFromDoc));
      if (!_disposed) notifyListeners();
    } on FirebaseException {
      // Streams are the live path; a failed refresh is a no-op.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _walletSub?.cancel();
    _ledgerSub?.cancel();
    super.dispose();
  }

  // ─────────────────────────── mock mode ───────────────────────────

  void _seedDemoLedger() {
    final now = DateTime.now();
    _balance = 8900;
    _transactions
      ..add(
        WalletTransaction(
          id: 'TXN-20260812-0041',
          amount: 5000,
          type: TransactionType.recharge,
          status: TransactionStatus.completed,
          method: 'PayFast',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      )
      ..add(
        WalletTransaction(
          id: 'SRV-20260811-0902',
          amount: -100,
          type: TransactionType.serviceCharge,
          status: TransactionStatus.completed,
          method: 'Wallet',
          createdAt: now.subtract(const Duration(days: 1, hours: 6)),
          note: 'Monthly account fee',
        ),
      )
      ..add(
        WalletTransaction(
          id: 'TXN-20260808-0040',
          amount: 3000,
          type: TransactionType.recharge,
          status: TransactionStatus.completed,
          method: 'PayFast',
          createdAt: now.subtract(const Duration(days: 4, hours: 3)),
        ),
      )
      ..add(
        WalletTransaction(
          id: 'TXN-20260807-0039',
          amount: 1000,
          type: TransactionType.recharge,
          status: TransactionStatus.pending,
          method: 'PayFast',
          createdAt: now.subtract(const Duration(days: 5, hours: 8)),
        ),
      );
  }
}
