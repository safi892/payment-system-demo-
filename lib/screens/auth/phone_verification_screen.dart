import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../constants/app_strings.dart';
import '../../services/service_locator.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons.dart';
import '../../widgets/mark_widgets.dart';
import '../../widgets/placard_label.dart';
import '../splash/splash_screen.dart';

/// Phone verification screen: the user must verify their phone number
/// before accessing the wallet panel. Three phases:
///   1. Phone number input (+92 prefix)
///   2. OTP entry (6 digit boxes)
///   3. Success animation + redirect
class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(AppConfig.otpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(AppConfig.otpLength, (_) => FocusNode());

  // ── State ────────────────────────────────────────────────────────
  _Phase _phase = _Phase.phone;
  bool _busy = false;
  String? _error;
  String _phoneNumber = '';
  String _verificationId = '';
  int _resendSeconds = 0;
  Timer? _resendTimer;
  Timer? _successTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }

  // ── Phone submission ─────────────────────────────────────────────

  Future<void> _sendCode() async {
    final phoneError = Validators.pakPhone(_phoneController.text);
    if (phoneError != null) {
      setState(() {
        _error = phoneError;
        _phase = _Phase.phone;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final intlPhone = Validators.phoneToIntl(_phoneController.text);
    _phoneNumber = intlPhone;

    await Services.auth.verifyPhoneNumber(
      phoneNumber: intlPhone,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        if (!mounted) return;
        setState(() {
          _phase = _Phase.otp;
          _busy = false;
          _error = null;
        });
        _startResendTimer();
        // Focus the first OTP box.
        Future.microtask(() => _otpFocusNodes[0].requestFocus());
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = error;
        });
      },
      onAutoVerified: (_) {
        // Auto-verification succeeded — navigate away.
        if (!mounted) return;
        _navigateToHome();
      },
    );
  }

  // ── OTP submission ───────────────────────────────────────────────

  Future<void> _verifyOTP() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != AppConfig.otpLength) {
      setState(() => _error = AppStrings.errOtpRequired);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await Services.auth.submitOTP(
        verificationId: _verificationId,
        smsCode: code,
        phoneNumber: _phoneNumber,
      );
      if (!mounted) return;
      setState(() {
        _phase = _Phase.success;
        _busy = false;
      });
      _successTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) _navigateToHome();
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      // Clear OTP fields on error.
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  // ── Resend timer ─────────────────────────────────────────────────

  void _startResendTimer() {
    _resendSeconds = AppConfig.otpResendCooldown.inSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;
    // Clear OTP fields.
    for (final c in _otpControllers) {
      c.clear();
    }
    await _sendCode();
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.luminous,
        elevation: 0,
        centerTitle: false,
        title: const PlacardLabel(
          AppStrings.verifyPhoneTitle,
          size: 11,
          spacing: 2.4,
          color: AppColors.dim,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _phase == _Phase.success
                    ? _buildSuccess()
                    : _phase == _Phase.otp
                        ? _buildOTP()
                        : _buildPhoneInput(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Phase 1: Phone input ─────────────────────────────────────────

  Widget _buildPhoneInput() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.verifyPhoneTitle,
          style: TextStyle(
            color: AppColors.luminous,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.verifyPhoneSubtitle,
          style: TextStyle(color: AppColors.dim, fontSize: 13.5),
        ),
        const SizedBox(height: 30),
        // Phone number field with +92 prefix.
        _buildPhoneField(),
        if (_error != null) ...[
          const SizedBox(height: 16),
          ErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),
        ],
        const SizedBox(height: 26),
        PrimaryButton(
          label: AppStrings.sendCode,
          onPressed: _busy ? null : _sendCode,
          busy: _busy,
        ),
        const SizedBox(height: 18),
        // Demo hint.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              const LampDot(WidgetStatus.info, size: 7),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.phoneDemoHint,
                  style: const TextStyle(
                    color: AppColors.dim,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final hasError = _error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlacardLabel(
          AppStrings.phoneNumber,
          color: AppColors.faint,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? AppColors.red : AppColors.hairline,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Country code prefix.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 54,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.hairline),
                  ),
                ),
                child: const Text(
                  AppConfig.phonePrefix,
                  style: TextStyle(
                    color: AppColors.luminous,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Phone input.
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneFormatters,
                  onChanged: (_) => setState(() => _error = null),
                  style: const TextStyle(
                    color: AppColors.luminous,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.radium,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: AppStrings.phoneHint,
                    hintStyle: TextStyle(
                      color: AppColors.faint,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const LampDot(WidgetStatus.failed, size: 6),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Phase 2: OTP entry ───────────────────────────────────────────

  Widget _buildOTP() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confirmation text.
        Text(
          '${AppStrings.otpSentTo}  $_phoneNumber',
          style: const TextStyle(
            color: AppColors.dim,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        const PlacardLabel(
          AppStrings.otpTitle,
          size: 11,
          spacing: 2,
          color: AppColors.faint,
        ),
        const SizedBox(height: 14),
        // OTP digit boxes.
        _buildOTPDigits(),
        if (_error != null) ...[
          const SizedBox(height: 16),
          ErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),
        ],
        const SizedBox(height: 26),
        PrimaryButton(
          label: AppStrings.verifyOtp,
          icon: Icons.check_rounded,
          onPressed: _busy ? null : _verifyOTP,
          busy: _busy,
        ),
        const SizedBox(height: 18),
        // Resend countdown or button.
        _buildResendRow(),
      ],
    );
  }

  Widget _buildOTPDigits() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(AppConfig.otpLength, (i) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: _otpControllers[i],
            focusNode: _otpFocusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              color: AppColors.luminous,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: AppColors.radium,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.input,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.hairline,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.radium,
                  width: 1.4,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() => _error = null);
              if (value.isNotEmpty && i < AppConfig.otpLength - 1) {
                _otpFocusNodes[i + 1].requestFocus();
              }
              // Auto-submit when all digits are filled.
              if (i == AppConfig.otpLength - 1 && value.isNotEmpty) {
                final code = _otpControllers.map((c) => c.text).join();
                if (code.length == AppConfig.otpLength) {
                  _verifyOTP();
                }
              }
            },
            onTap: () {
              // Select all text on tap for easy replacement.
              _otpControllers[i].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _otpControllers[i].text.length,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendRow() {
    if (_resendSeconds > 0) {
      return Center(
        child: Text(
          '${AppStrings.resendCode} ${_resendSeconds}s',
          style: const TextStyle(
            color: AppColors.dim,
            fontSize: 12.5,
          ),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: _resendCode,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.radium,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        child: const Text(AppStrings.resendNow),
      ),
    );
  }

  // ── Phase 3: Success ─────────────────────────────────────────────

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.radiumSoft,
              border: Border.all(
                color: AppColors.radium,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.radium,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          AppStrings.phoneVerified,
          style: TextStyle(
            color: AppColors.luminous,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.phoneVerifiedBody,
          style: TextStyle(
            color: AppColors.dim,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

enum _Phase { phone, otp, success }
