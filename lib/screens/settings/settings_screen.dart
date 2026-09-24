import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../models/payfast_config.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/placard_label.dart';

/// Panel preferences and gateway configuration.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _biometric = false;
  bool _dataSaver = false;
  PayFastConfig? _payfastConfig;

  @override
  void initState() {
    super.initState();
    _loadPayFastConfig();
  }

  Future<void> _loadPayFastConfig() async {
    final cfg = await Services.payfast.getConfig();
    if (mounted) setState(() => _payfastConfig = cfg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.luminous,
        elevation: 0,
        title: const Text(
          AppStrings.settingsTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PlacardLabel(
              'PREFERENCES',
              size: 10,
              spacing: 2,
              color: AppColors.faint,
            ),
            const SizedBox(height: 10),
            _toggleTile(
              icon: Icons.notifications_none_rounded,
              title: AppStrings.settingsNotifications,
              body: AppStrings.settingsNotificationsBody,
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            _toggleTile(
              icon: Icons.fingerprint_rounded,
              title: AppStrings.settingsBiometric,
              body: AppStrings.settingsBiometricBody,
              value: _biometric,
              onChanged: (v) => setState(() => _biometric = v),
            ),
            _toggleTile(
              icon: Icons.dark_mode_outlined,
              title: AppStrings.settingsDark,
              body: AppStrings.settingsDarkBody,
              value: true,
              onChanged: null,
            ),
            _toggleTile(
              icon: Icons.data_saver_on_rounded,
              title: AppStrings.settingsDataSaver,
              body: AppStrings.settingsDataSaverBody,
              value: _dataSaver,
              onChanged: (v) => setState(() => _dataSaver = v),
            ),
            const SizedBox(height: 26),
            const PlacardLabel(
              'PAYMENT GATEWAY (PAYFAST)',
              size: 10,
              spacing: 2,
              color: AppColors.faint,
            ),
            const SizedBox(height: 10),
            // ── Sandbox active banner ──
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.radium, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'PayFast Pakistan API integrated · Sandbox active · Merchant ID 14833',
                              style: TextStyle(color: AppColors.luminous, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.surfaceRaised,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.radium.withValues(alpha: 0.4)),
                      ),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    ),
                  );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.radiumSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.radium.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 15, color: AppColors.radium),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'PayFast Sandbox · LIVE API INTEGRATED · Tap for info',
                        style: TextStyle(
                          color: AppColors.radium,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.radium,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _payfastGatewayTile(),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.radium,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      AppStrings.aboutBody,
                      style: TextStyle(
                        color: AppColors.dim,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlacardLabel(
                  '${AppStrings.version}  1.0.0',
                  size: 9.5,
                  spacing: 1.6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _payfastGatewayTile() {
    final cfg = _payfastConfig;
    final isEnabled = cfg?.isEnabled ?? false;
    final merchant = cfg != null && cfg.merchantId.isNotEmpty ? cfg.merchantId : 'Not Configured';
    final envName = cfg?.environment.name.toUpperCase() ?? 'SANDBOX';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppColors.radium.withValues(alpha: 0.5) : AppColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.radiumSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payment_rounded, color: AppColors.radium, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PayFast Pakistan API',
                      style: TextStyle(
                        color: AppColors.luminous,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Merchant: $merchant · $envName',
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: cfg == null
                    ? null
                    : (val) async {
                        cfg.isEnabled = val;
                        await Services.payfast.updateConfig(cfg);
                        setState(() => _payfastConfig = cfg);
                      },
                activeThumbColor: AppColors.radium,
                activeTrackColor: AppColors.radiumSoft,
                inactiveTrackColor: AppColors.hairline,
                inactiveThumbColor: AppColors.dim,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Enables live/sandbox PayFast API checkout with token auth, 3DS cards, and mobile wallets (JazzCash & EasyPaisa).',
            style: TextStyle(color: AppColors.dim, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Configure Credentials'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.radium,
                    side: const BorderSide(color: AppColors.radium),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _openPayFastConfigSheet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openPayFastConfigSheet() async {
    final cfg = await Services.payfast.getConfig();
    final merchantCtrl = TextEditingController(text: cfg.merchantId);
    final keyCtrl = TextEditingController(text: cfg.securedKey);
    final urlCtrl = TextEditingController(text: cfg.baseUrl);
    PayFastEnvironment env = cfg.environment;
    bool obscureKey = true;
    bool testing = false;
    String? testStatusMessage;
    bool? testSuccess;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PayFast API Credentials',
                            style: TextStyle(
                              color: AppColors.luminous,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.dim, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Set your PayFast Pakistan merchant credentials or test keys to process transactions.',
                        style: TextStyle(color: AppColors.dim, fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _envSelector(
                              title: 'Sandbox',
                              selected: env == PayFastEnvironment.sandbox,
                              onTap: () {
                                setModalState(() {
                                  env = PayFastEnvironment.sandbox;
                                  urlCtrl.text = PayFastConfig.defaultSandboxUrl;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _envSelector(
                              title: 'Production',
                              selected: env == PayFastEnvironment.production,
                              onTap: () {
                                setModalState(() {
                                  env = PayFastEnvironment.production;
                                  urlCtrl.text = PayFastConfig.defaultProductionUrl;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Merchant ID',
                        controller: merchantCtrl,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Secured Key',
                        controller: keyCtrl,
                        prefixIcon: Icons.key_outlined,
                        obscure: obscureKey,
                        suffix: IconButton(
                          icon: Icon(
                            obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppColors.dim,
                          ),
                          onPressed: () => setModalState(() => obscureKey = !obscureKey),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Gateway Base URL',
                        controller: urlCtrl,
                        prefixIcon: Icons.link_rounded,
                      ),
                      if (testStatusMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: testSuccess == true ? AppColors.radiumSoft : AppColors.redSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: testSuccess == true ? AppColors.radium : AppColors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline,
                                color: testSuccess == true ? AppColors.radium : AppColors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  testStatusMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: testSuccess == true ? AppColors.radium : AppColors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.luminous,
                                side: const BorderSide(color: AppColors.hairline),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: testing
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        testing = true;
                                        testStatusMessage = null;
                                      });
                                      final res = await Services.payfast.testConnection(
                                        merchantId: merchantCtrl.text.trim(),
                                        securedKey: keyCtrl.text.trim(),
                                        baseUrl: urlCtrl.text.trim(),
                                      );
                                      setModalState(() {
                                        testing = false;
                                        testSuccess = res.success;
                                        testStatusMessage = res.message;
                                      });
                                    },
                              child: testing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.radium),
                                    )
                                  : const Text('Test Connection'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Save Settings',
                              onPressed: () async {
                                cfg.merchantId = merchantCtrl.text.trim();
                                cfg.securedKey = keyCtrl.text.trim();
                                cfg.environment = env;
                                cfg.baseUrl = urlCtrl.text.trim();
                                cfg.isEnabled = true;
                                await Services.payfast.updateConfig(cfg);
                                if (mounted) {
                                  setState(() => _payfastConfig = cfg);
                                }
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              merchantCtrl.text = '10001';
                              keyCtrl.text = 'sandbox_test_key_pk';
                              env = PayFastEnvironment.sandbox;
                              urlCtrl.text = PayFastConfig.defaultSandboxUrl;
                            });
                          },
                          child: const Text(
                            'Reset to Sandbox Defaults',
                            style: TextStyle(color: AppColors.dim, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _envSelector({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.radiumSoft : AppColors.input,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.radium : AppColors.hairline,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.radium : AppColors.dim,
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String body,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.radium),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.luminous,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.faint,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.radium,
              activeTrackColor: AppColors.radiumSoft,
              inactiveTrackColor: AppColors.hairline,
              inactiveThumbColor: AppColors.dim,
            ),
          ],
        ),
      ),
    );
  }
}
