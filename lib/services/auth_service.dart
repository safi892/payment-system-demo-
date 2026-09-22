import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';
import '../firebase/firebase_bootstrap.dart';
import '../models/app_user.dart';
import 'service_locator.dart';

/// Authentication service.
///
/// Dual-mode by design (Phase 3):
///  - Firebase configured  → real Firebase Auth + Firestore profile/wallet
///  - Firebase unavailable → in-memory mock store + persisted session flag
///
/// Screens only call login/register/logout/restoreSession — the exact
/// interface is identical in both modes.
class AuthService {
  final Map<String, _MockUser> _users = {};
  AppUser? _currentUser;

  AuthService() {
    _seedDemoAccount();
  }

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isPhoneVerified => _currentUser?.phoneVerified ?? false;
  bool get _firebaseMode => FirebaseBootstrap.configured;

  void _seedDemoAccount() {
    final mock = _MockUser(
      user: AppUser(
        id: 'demo-001',
        name: AppConfig.demoName,
        email: AppConfig.demoEmail,
        createdAt: DateTime(2026, 6, 1),
        phoneVerified: true,
      ),
      password: AppConfig.demoPassword,
    );
    _users[AppConfig.demoEmail] = mock;
  }

  /// Restores the persisted session, called from the splash screen.
  /// Firebase mode: auth state is restored natively by the SDK.
  /// Mock mode: reads the SharedPreferences session flag.
  Future<void> restoreSession() async {
    if (_firebaseMode) {
      final User? user = await FirebaseAuth.instance.authStateChanges().first;
      if (user != null) {
        final profile = await _loadProfileFromFirestore(user.uid);
        _activate(profile ?? _fromFirebaseUser(user));
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppConfig.sharedPrefsSessionKey);
    if (email != null && _users.containsKey(email)) {
      _activate(_users[email]!.user);
    }
  }

  Future<AppUser> login(String email, String password) async {
    final key = email.trim().toLowerCase();
    if (_firebaseMode) {
      await Future.delayed(AppConfig.authLatency);
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: key,
          password: password,
        );
        final profile = await _loadProfileFromFirestore(cred.user!.uid);
        final user = profile ?? _fromFirebaseUser(cred.user!);
        _activate(user);
        return user;
      } on FirebaseAuthException catch (e) {
        throw AppException(_mapAuthError(e));
      }
    }
    await Future.delayed(AppConfig.authLatency);
    final mock = _users[key];
    if (mock == null || mock.password != password) {
      throw const AppException('Invalid email or password.');
    }
    _activate(mock.user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.sharedPrefsSessionKey, key);
    return mock.user;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_firebaseMode) {
      await Future.delayed(AppConfig.authLatency);
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: key,
          password: password,
        );
        await cred.user?.updateDisplayName(name.trim());
        final user = _fromFirebaseUser(cred.user!);
        await _seedProfile(user, name.trim());
        _activate(user);
        return user;
      } on FirebaseAuthException catch (e) {
        throw AppException(_mapAuthError(e));
      }
    }
    await Future.delayed(AppConfig.authLatency);
    if (_users.containsKey(key)) {
      throw const AppException('An account with this email already exists.');
    }
    final user = AppUser(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: key,
      createdAt: DateTime.now(),
    );
    _users[key] = _MockUser(user: user, password: password);
    _activate(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.sharedPrefsSessionKey, key);
    return user;
  }

  Future<void> logout() async {
    if (_firebaseMode) {
      await FirebaseAuth.instance.signOut();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.sharedPrefsSessionKey);
    }
    _currentUser = null;
    Services.wallet.detach();
  }

  /// Creates the Firestore profile + zero-balance wallet for a new user.
  /// The wallet seed itself (demo history) is handled by WalletService.
  Future<void> _seedProfile(AppUser user, String name) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final firestore = FirebaseFirestore.instance;
    try {
      await firestore.collection('users').doc(user.id).set({
        'name': name,
        'email': user.email,
        'phoneVerified': false,
        'createdAt': now,
        'updatedAt': now,
      });
    } on FirebaseException {
      // Profile write is best-effort: auth already succeeded.
    }
  }

  AppUser _fromFirebaseUser(User user) {
    final email = user.email ?? '';
    final name = user.displayName ?? _nameFromEmail(email);
    return AppUser(
      id: user.uid,
      name: name,
      email: email,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// Reads the full user profile from Firestore (including phone fields).
  Future<AppUser?> _loadProfileFromFirestore(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return AppUser(
        id: uid,
        name: (data['name'] as String?) ?? _nameFromEmail(
          FirebaseAuth.instance.currentUser?.email ?? '',
        ),
        email: (data['email'] as String?) ??
            FirebaseAuth.instance.currentUser?.email ??
            '',
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
        phoneNumber: data['phoneNumber'] as String?,
        phoneVerified: data['phoneVerified'] as bool? ?? false,
      );
    } on FirebaseException {
      return null;
    }
  }

  /// Updates the phone verification status in Firestore and local state.
  Future<void> _markPhoneVerified(String phoneNumber) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = AppUser(
      id: user.id,
      name: user.name,
      email: user.email,
      createdAt: user.createdAt,
      phoneNumber: phoneNumber,
      phoneVerified: true,
    );

    if (_firebaseMode) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'phoneNumber': phoneNumber,
          'phoneVerified': true,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
      } on FirebaseException {
        // Best-effort: local state is already updated.
      }
    }
  }

  // ── Phone verification ─────────────────────────────────────────────

  /// Initiates phone number verification.
  ///
  /// Firebase mode: sends a real SMS OTP to [phoneNumber].
  /// Simulated mode: pretends to send; calls onCodeSent immediately.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(String verificationId)? onAutoVerified,
  }) async {
    if (_firebaseMode) {
      if (kDebugMode) {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval on Android: sign in directly.
          try {
            await FirebaseAuth.instance.currentUser
                ?.linkWithCredential(credential);
            await _markPhoneVerified(phoneNumber);
            onAutoVerified?.call('');
          } on FirebaseAuthException {
            // Fallback: let user enter OTP manually.
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError.call(_mapPhoneError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent.call(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // No-op: verificationId is already available via codeSent.
        },
      );
    } else {
      // Simulated mode: pretend to send after a short delay.
      await Future.delayed(const Duration(milliseconds: 800));
      final fakeId = 'sim-${DateTime.now().millisecondsSinceEpoch}';
      onCodeSent.call(fakeId);
    }
  }

  /// Submits the OTP code for verification.
  ///
  /// Firebase mode: creates a PhoneAuthCredential and links it to the user.
  /// Simulated mode: accepts any 6-digit string.
  Future<void> submitOTP({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    if (_firebaseMode) {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      try {
        await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        throw AppException(_mapPhoneSubmitError(e));
      }
      await _markPhoneVerified(phoneNumber);
    } else {
      // Simulated mode: accept any 6-digit code.
      await Future.delayed(const Duration(milliseconds: 500));
      if (smsCode.length != AppConfig.otpLength || !_isNumeric(smsCode)) {
        throw const AppException('Enter a valid 6-digit code.');
      }
      await _markPhoneVerified(phoneNumber);
    }
  }

  bool _isNumeric(String s) => int.tryParse(s) != null;

  String _mapPhoneError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-phone-number' => 'Invalid phone number.',
      'too-many-requests' => 'Too many attempts. Wait a moment.',
      'quota-exceeded' => 'SMS quota exceeded. Try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => 'Verification failed (${e.code}).',
    };
  }

  String _mapPhoneSubmitError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-verification-code' => 'Invalid code. Check and try again.',
      'session-expired' => 'Code expired. Request a new one.',
      'credential-already-in-use' => 'This phone number is already linked to another account.',
      'invalid-credential' => 'Invalid code. Check and try again.',
      _ => 'Verification failed (${e.code}).',
    };
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'Pilot';
    return local[0].toUpperCase() + local.substring(1);
  }

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Invalid email or password.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password must be at least 6 characters.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => 'Authentication failed (${e.code}).',
    };
  }

  void _activate(AppUser user) {
    _currentUser = user;
    Services.wallet.attach(user);
  }
}

class _MockUser {
  const _MockUser({required this.user, required this.password});
  final AppUser user;

  /// Plaintext only because this is a demo store. Real credentials live in
  /// Firebase Auth (Phase 3) — never in client code.
  final String password;
}
