/// Tunable app configuration. All values are demo defaults; the backend
/// phase will replace the simulation rules with real gateway behaviour.
abstract final class AppConfig {
  /// Recharge presets shown on the recharge screen (whole PKR).
  static const List<int> presetAmounts = [500, 1000, 5000];

  static const double minAmount = 1;
  static const double maxAmount = 1000000;

  /// Demo account seeded for Phase 1 (no backend yet).
  static const String demoEmail = 'ali@demo.com';
  static const String demoPassword = 'demo1234';
  static const String demoName = 'Ali Raza';

  /// Simulated gateway rules, documented for the demo script:
  /// any other amount succeeds, 9999 = card declined, 8888 = timeout.
  static const double simulateDeclineAmount = 9999;
  static const double simulateTimeoutAmount = 8888;

  /// Artificial latencies that mimic network + gateway round-trips.
  static const Duration authLatency = Duration(milliseconds: 700);
  static const Duration syncLatency = Duration(milliseconds: 600);
  static const Duration paymentLatency = Duration(milliseconds: 2400);
  static const Duration splashDuration = Duration(milliseconds: 1900);

  /// Payment simulation step timing (must sum to paymentLatency).
  static const List<Duration> paymentSteps = [
    Duration(milliseconds: 800),
    Duration(milliseconds: 900),
    Duration(milliseconds: 700),
  ];

  static const String sharedPrefsSessionKey = 'session_email';

  /// Phone verification config.
  static const Duration otpResendCooldown = Duration(seconds: 30);
  static const int otpLength = 6;
  static const String phonePrefix = '+92';
  static const int phoneLocalLength = 11; // 03XXXXXXXXX
}
