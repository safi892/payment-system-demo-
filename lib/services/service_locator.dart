import 'auth_service.dart';
import 'payment_service.dart';
import 'wallet_service.dart';

/// Hand-rolled dependency container. Screens never construct services;
/// they read them from here, which is what lets later phases swap the
/// mocked implementations for Firebase / backend-backed ones untouched.
abstract final class Services {
  static final AuthService auth = AuthService();
  static final WalletService wallet = WalletService();
  static final PaymentService payment = PaymentService();
}

/// The single error shape the UI knows how to render.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}
