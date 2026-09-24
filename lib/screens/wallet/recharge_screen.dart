import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../constants/app_strings.dart';
import '../../models/payment_result.dart';
import '../../services/service_locator.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/amount_chip.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/placard_label.dart';
import '../../widgets/step_indicator.dart';
import 'payfast_checkout_modal.dart';

/// Recharge flow: pick a preset or custom amount, then run the payment
/// simulation (create → confirm → verify) or the real PayFast checkout.
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  double? _selected;
  bool _customMode = false;
  final _customController = TextEditingController();
  String? _amountError;
  bool _busy = false;
  bool _usePayFast = false;

  @override
  void initState() {
    super.initState();
    _loadGatewayPreference();
  }

  Future<void> _loadGatewayPreference() async {
    final cfg = await Services.payfast.getConfig();
    if (mounted) setState(() => _usePayFast = cfg.isEnabled);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  double? get _effectiveAmount {
    if (_customMode) {
      final v = Validators.amount(_customController.text);
      return v == null
          ? double.tryParse(_customController.text.replaceAll(',', ''))
          : null;
    }
    return _selected;
  }

  bool get _canContinue {
    if (_customMode) {
      return Validators.amount(_customController.text) == null;
    }
    return _selected != null;
  }

  void _select(double amount) {
    setState(() {
      _selected = amount;
      _customMode = false;
      _amountError = null;
    });
  }

  void _enableCustom() {
    setState(() {
      _customMode = true;
      _selected = null;
      _amountError = null;
    });
  }

  Future<void> _startPayment() async {
    final amount = _effectiveAmount;
    if (amount == null) return;

    if (_usePayFast) {
      final payFastResult = await PayFastCheckoutModal.show(context, amount);
      if (payFastResult == null) return;
      if (!mounted) return;

      if (payFastResult.isSuccess) {
        Services.wallet.credit(
          amount: amount,
          transactionId: payFastResult.transactionId,
          method: payFastResult.method,
        );
      }
      await _showOutcome(payFastResult);
      return;
    }

    setState(() => _busy = true);
    final result = await Services.payment.recharge(amount);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.isSuccess) {
      Services.wallet.credit(
        amount: amount,
        transactionId: result.transactionId,
        method: 'PayFast',
      );
    }
    await _showOutcome(result);
  }

  Future<void> _showOutcome(PaymentResult result) async {
    final action = await showModalBottomSheet<_OutcomeAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OutcomeSheet(result: result),
    );
    if (!mounted) return;
    if (action == _OutcomeAction.retry) {
      await _startPayment();
    } else {
      Navigator.of(context).pop();
    }
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
          AppStrings.rechargeTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          child: _busy
              ? const _ProcessingOverlay(key: ValueKey('processing'))
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListenableBuilder(
      listenable: Services.wallet,
      builder: (context, _) {
        final balance = Services.wallet.balance;
        return ListView(
          key: const ValueKey('form'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                const PlacardLabel(
                  AppStrings.currentBalance,
                  color: AppColors.faint,
                ),
                const Spacer(),
                Text(
                  Formatters.currency(balance),
                  style: const TextStyle(
                    color: AppColors.luminous,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const PlacardLabel(AppStrings.selectAmount, size: 11, spacing: 2),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in AppConfig.presetAmounts)
                  AmountChip(
                    label: 'PKR ${Formatters.amount(preset)}',
                    amount: preset.toDouble(),
                    selected: !_customMode && _selected == preset,
                    onTap: () => _select(preset.toDouble()),
                  ),
                AmountChip(
                  label: AppStrings.custom,
                  amount: 0,
                  selected: _customMode,
                  onTap: _enableCustom,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _customMode
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: AppTextField(
                        label: AppStrings.customAmount,
                        controller: _customController,
                        errorText: _amountError,
                        keyboardType: TextInputType.number,
                        inputFormatters: amountFormatters,
                        onChanged: (_) => setState(() {
                          _amountError = Validators.amount(
                            _customController.text,
                          );
                        }),
                        prefixIcon: Icons.payments_outlined,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: AppStrings.continuePayment,
              icon: Icons.arrow_forward_rounded,
              onPressed: _canContinue && !_busy ? _startPayment : null,
              busy: _busy,
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () async {
                final next = !_usePayFast;
                setState(() => _usePayFast = next);
                final cfg = await Services.payfast.getConfig();
                cfg.isEnabled = next;
                await Services.payfast.updateConfig(cfg);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _usePayFast ? AppColors.radium.withValues(alpha: 0.6) : AppColors.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    LampDot(_usePayFast ? WidgetStatus.completed : WidgetStatus.info, size: 7),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _usePayFast ? 'GATEWAY: PAYFAST PAKISTAN · CHECKOUT ACTIVE' : AppStrings.paymentSimulated,
                        style: TextStyle(
                          color: _usePayFast ? AppColors.radium : AppColors.dim,
                          fontSize: 11.5,
                          fontWeight: _usePayFast ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      _usePayFast ? Icons.check_circle_outline_rounded : Icons.swap_horiz_rounded,
                      size: 16,
                      color: _usePayFast ? AppColors.radium : AppColors.dim,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                _usePayFast
                    ? 'Card 3DS & Mobile Wallets (JazzCash/EasyPaisa) test checkout with OTP.'
                    : 'Tap above to switch to PayFast Gateway or keep fast simulation.',
                style: const TextStyle(
                  color: AppColors.faint,
                  fontSize: 9,
                  letterSpacing: 0.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _OutcomeAction { retry, close }

/// Result sheet: success shows the credit reading; decline and timeout
/// show the failed lamp with a retry path. No balance is touched on
/// failure, mirroring server-side verification behaviour.
class _OutcomeSheet extends StatefulWidget {
  const _OutcomeSheet({required this.result});

  final PaymentResult result;

  @override
  State<_OutcomeSheet> createState() => _OutcomeSheetState();
}

class _OutcomeSheetState extends State<_OutcomeSheet> {
  @override
  Widget build(BuildContext context) {
    final success = widget.result.isSuccess;
    final title = success
        ? AppStrings.paymentSuccessTitle
        : widget.result.status == PaymentStatus.declined
        ? AppStrings.paymentDeclinedTitle
        : AppStrings.paymentTimeoutTitle;
    final body = success
        ? AppStrings.paymentSuccessBody
        : widget.result.status == PaymentStatus.declined
        ? AppStrings.paymentDeclinedBody
        : AppStrings.paymentTimeoutBody;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success ? AppColors.radiumSoft : AppColors.redSoft,
                  border: Border.all(
                    color: success ? AppColors.radium : AppColors.red,
                    width: 1.4,
                  ),
                ),
                child: Icon(
                  success ? Icons.check_rounded : Icons.close_rounded,
                  color: success ? AppColors.radium : AppColors.red,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.luminous,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.dim,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            if (success) ...[
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    _readout(
                      AppStrings.transactionId,
                      widget.result.transactionId,
                    ),
                    const SizedBox(height: 12),
                    _readout(
                      AppStrings.amount,
                      Formatters.currency(widget.result.amount),
                    ),
                    const SizedBox(height: 12),
                    _readout(AppStrings.method, widget.result.method),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            success
                ? PrimaryButton(
                    label: AppStrings.done,
                    icon: Icons.check_rounded,
                    onPressed: () =>
                        Navigator.of(context).pop(_OutcomeAction.close),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: AppStrings.cancel,
                          onPressed: () =>
                              Navigator.of(context).pop(_OutcomeAction.close),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: AppStrings.retry,
                          onPressed: () =>
                              Navigator.of(context).pop(_OutcomeAction.retry),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _readout(String label, String value) {
    return Row(
      children: [
        PlacardLabel(label, size: 9.5, spacing: 1.4, color: AppColors.faint),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.luminous,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Full-panel processing overlay: the three-stage cross-check
/// (create → confirm → verify) runs in place before the outcome sheet.
class _ProcessingOverlay extends StatefulWidget {
  const _ProcessingOverlay({super.key});

  @override
  State<_ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<_ProcessingOverlay> {
  final List<StepPhase> _steps = [
    StepPhase.pending,
    StepPhase.pending,
    StepPhase.pending,
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < AppConfig.paymentSteps.length; i++) {
      await Future<void>.delayed(AppConfig.paymentSteps[i]);
      if (!mounted) return;
      setState(() => _steps[i] = StepPhase.done);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.panel,
      padding: const EdgeInsets.fromLTRB(32, 120, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.processingTitle,
            style: TextStyle(
              color: AppColors.luminous,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.paymentSimulated,
            style: TextStyle(color: AppColors.dim, fontSize: 12),
          ),
          const SizedBox(height: 32),
          StepRow(label: AppStrings.stepCreate, state: _steps[0]),
          const SizedBox(height: 20),
          StepRow(label: AppStrings.stepConfirm, state: _steps[1]),
          const SizedBox(height: 20),
          StepRow(label: AppStrings.stepVerify, state: _steps[2]),
          const SizedBox(height: 40),
          LinearProgressIndicator(
            value: null,
            color: AppColors.radium,
            backgroundColor: AppColors.hairline,
            minHeight: 2,
          ),
        ],
      ),
    );
  }
}
