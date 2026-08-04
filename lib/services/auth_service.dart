import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';
import '../models/app_user.dart';
import 'service_locator.dart';

/// Authentication backed by an in-memory mock user store plus a persisted
/// session flag. Phase 3 replaces the internals with Firebase Auth while
/// keeping this exact interface — screens only call login/register/logout.
class AuthService {
  final Map<String, _MockUser> _users = {};
  AppUser? _currentUser;

  AuthService() {
    _seedDemoAccount();
  }

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  void _seedDemoAccount() {
    final mock = _MockUser(
      user: AppUser(
        id: 'demo-001',
        name: AppConfig.demoName,
        email: AppConfig.demoEmail,
        createdAt: DateTime(2026, 6, 1),
      ),
      password: AppConfig.demoPassword,
    );
    _users[AppConfig.demoEmail] = mock;
  }

  /// Restores the persisted session, called from the splash screen.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppConfig.sharedPrefsSessionKey);
    if (email != null && _users.containsKey(email)) {
      _activate(_users[email]!.user);
    }
  }

  Future<AppUser> login(String email, String password) async {
    await Future.delayed(AppConfig.authLatency);
    final key = email.trim().toLowerCase();
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
    await Future.delayed(AppConfig.authLatency);
    final key = email.trim().toLowerCase();
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
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.sharedPrefsSessionKey);
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
