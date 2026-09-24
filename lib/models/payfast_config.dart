import 'package:shared_preferences/shared_preferences.dart';

enum PayFastEnvironment {
  sandbox,
  production,
}

class PayFastConfig {
  PayFastConfig({
    required this.merchantId,
    required this.securedKey,
    required this.environment,
    required this.baseUrl,
    required this.isEnabled,
  });

  String merchantId;
  String securedKey;
  PayFastEnvironment environment;
  String baseUrl;
  bool isEnabled;

  static const String defaultSandboxUrl = 'https://ipguat.apps.net.pk';
  static const String defaultProductionUrl = 'https://api.payfast.com';

  static const String _prefKeyMerchantId = 'payfast_merchant_id';
  static const String _prefKeySecuredKey = 'payfast_secured_key';
  static const String _prefKeyEnv = 'payfast_environment';
  static const String _prefKeyBaseUrl = 'payfast_base_url';
  static const String _prefKeyEnabled = 'payfast_is_enabled';

  static PayFastConfig defaults() {
    return PayFastConfig(
      merchantId: '14833',
      securedKey: 'rPcy4T7GQkSCFsHBLdn26s',
      environment: PayFastEnvironment.sandbox,
      baseUrl: defaultSandboxUrl,
      isEnabled: true,
    );
  }

  static Future<PayFastConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final merchantId = prefs.getString(_prefKeyMerchantId) ?? '14833';
    final securedKey = prefs.getString(_prefKeySecuredKey) ?? 'rPcy4T7GQkSCFsHBLdn26s';
    final envStr = prefs.getString(_prefKeyEnv) ?? 'sandbox';
    final env = envStr == 'production' ? PayFastEnvironment.production : PayFastEnvironment.sandbox;
    final defaultUrl = env == PayFastEnvironment.production ? defaultProductionUrl : defaultSandboxUrl;
    final baseUrl = prefs.getString(_prefKeyBaseUrl) ?? defaultUrl;
    final isEnabled = prefs.getBool(_prefKeyEnabled) ?? true;

    return PayFastConfig(
      merchantId: merchantId,
      securedKey: securedKey,
      environment: env,
      baseUrl: baseUrl,
      isEnabled: isEnabled,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyMerchantId, merchantId);
    await prefs.setString(_prefKeySecuredKey, securedKey);
    await prefs.setString(_prefKeyEnv, environment.name);
    await prefs.setString(_prefKeyBaseUrl, baseUrl);
    await prefs.setBool(_prefKeyEnabled, isEnabled);
  }
}
