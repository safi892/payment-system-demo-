import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/payment_result.dart';
import '../../services/service_locator.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/placard_label.dart';

enum _PaymentTab { card, wallet }

class PayFastCheckoutModal extends StatefulWidget {
  const PayFastCheckoutModal({
    super.key,
    required this.amount,
  });

  final double amount;

  static Future<PaymentResult?> show(BuildContext context, double amount) {
    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PayFastCheckoutModal(amount: amount),
    );
  }

  @override
  State<PayFastCheckoutModal> createState() => _PayFastCheckoutModalState();
}

class _PayFastCheckoutModalState extends State<PayFastCheckoutModal> {
  _PaymentTab _currentTab = _PaymentTab.card;

  // Card form controllers
  final _cardNumberController = TextEditingController(text: '4111 1111 1111 1111');
  final _expiryController = TextEditingController(text: '12/28');
  final _cvvController = TextEditingController(text: '123');
  final _cardholderController = TextEditingController(text: 'Ali Raza');

  // Wallet form controllers
  String _selectedWallet = 'jazzcash'; // 'jazzcash' or 'easypaisa'
  final _walletMobileController = TextEditingController(text: '03001234567');

  // OTP step
  bool _inOtpStep = false;
  String _activeTransactionId = '';
  final _otpController = TextEditingController();
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    _walletMobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _generateBasketId() {
    final now = DateTime.now();
    final millis = now.millisecondsSinceEpoch % 100000;
    return 'PF-${now.year}${now.month.toString().padLeft(2, '0')}-$millis';
  }

  Future<void> _submitInitialPayment() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final basketId = _generateBasketId();
    final email = Services.auth.currentUser?.email ?? 'test@gopayfast.com';

    try {
      if (_currentTab == _PaymentTab.card) {
        final expParts = _expiryController.text.split('/');
        final expMonth = expParts.isNotEmpty ? expParts[0].trim() : '12';
        final expYear = expParts.length > 1 ? expParts[1].trim() : '28';

        final res = await Services.payfast.processCardPayment(
          amount: widget.amount,
          basketId: basketId,
          cardNumber: _cardNumberController.text,
          expiryMonth: expMonth,
          expiryYear: expYear,
          cvv: _cvvController.text,
          customerEmail: email,
          customerMobile: '03001234567',
        );

        if (!mounted) return;
        setState(() => _busy = false);

        if (!res.success) {
          setState(() => _errorMessage = res.message ?? 'Payment failed.');
          return;
        }

        if (res.requiresOtp) {
          setState(() {
            _inOtpStep = true;
            _activeTransactionId = res.transactionId;
          });
        } else {
          Navigator.of(context).pop(
            PaymentResult.success(
              transactionId: res.transactionId,
              amount: widget.amount,
              method: 'PayFast · Card',
            ),
          );
        }
      } else {
        final res = await Services.payfast.processWalletPayment(
          amount: widget.amount,
          basketId: basketId,
          walletType: _selectedWallet,
          mobileNumber: _walletMobileController.text,
          customerEmail: email,
        );

        if (!mounted) return;
        setState(() => _busy = false);

        if (!res.success) {
          setState(() => _errorMessage = res.message ?? 'Payment failed.');
          return;
        }

        setState(() {
          _inOtpStep = true;
          _activeTransactionId = res.transactionId;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _submitOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification OTP.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final res = await Services.payfast.verifyOtp(
        transactionId: _activeTransactionId,
        otp: otp,
      );

      if (!mounted) return;
      setState(() => _busy = false);

      if (res.success) {
        final methodName = _currentTab == _PaymentTab.card
            ? 'PayFast · Card'
            : 'PayFast · ${_selectedWallet == 'jazzcash' ? 'JazzCash' : 'EasyPaisa'}';

        Navigator.of(context).pop(
          PaymentResult.success(
            transactionId: res.transactionId,
            amount: widget.amount,
            method: methodName,
          ),
        );
      } else {
        setState(() => _errorMessage = res.message ?? 'Invalid OTP code.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _inOtpStep ? _buildOtpView() : _buildPaymentForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      key: const ValueKey('form_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.radiumSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.radium.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: AppColors.radium),
                      SizedBox(width: 5),
                      Text(
                        'PAYFAST 3DS SECURE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.radium,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.dim, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const PlacardLabel('RECHARGE AMOUNT', size: 10, color: AppColors.faint),
            const Spacer(),
            Text(
              Formatters.currency(widget.amount),
              style: const TextStyle(
                color: AppColors.luminous,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: _tabButton(
                  title: 'Cards',
                  icon: Icons.credit_card_rounded,
                  selected: _currentTab == _PaymentTab.card,
                  onTap: () => setState(() => _currentTab = _PaymentTab.card),
                ),
              ),
              Expanded(
                child: _tabButton(
                  title: 'Mobile Wallets',
                  icon: Icons.account_balance_wallet_outlined,
                  selected: _currentTab == _PaymentTab.wallet,
                  onTap: () => setState(() => _currentTab = _PaymentTab.wallet),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_currentTab == _PaymentTab.card) _buildCardFields() else _buildWalletFields(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Pay ${Formatters.currency(widget.amount)}',
          icon: Icons.lock_outline_rounded,
          onPressed: _busy ? null : _submitInitialPayment,
          busy: _busy,
        ),
      ],
    );
  }

  Widget _tabButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: AppColors.hairline) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.radium : AppColors.dim),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.luminous : AppColors.dim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PlacardLabel('CARD DETAILS', size: 9.5, color: AppColors.faint),
            GestureDetector(
              onTap: () {
                _cardNumberController.text = '4111 1111 1111 1111';
                _expiryController.text = '12/28';
                _cvvController.text = '123';
                _cardholderController.text = 'Ali Raza';
                setState(() {});
              },
              child: const Text(
                'Fill Test Card',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.radium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppTextField(
          label: 'Card Number',
          controller: _cardNumberController,
          prefixIcon: Icons.credit_card,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Expiry (MM/YY)',
                controller: _expiryController,
                prefixIcon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.datetime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'CVV',
                controller: _cvvController,
                prefixIcon: Icons.lock_outline,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Cardholder Name',
          controller: _cardholderController,
          prefixIcon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildWalletFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlacardLabel('SELECT PROVIDER', size: 9.5, color: AppColors.faint),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _walletChip(
                name: 'JazzCash',
                selected: _selectedWallet == 'jazzcash',
                onTap: () => setState(() => _selectedWallet = 'jazzcash'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _walletChip(
                name: 'EasyPaisa',
                selected: _selectedWallet == 'easypaisa',
                onTap: () => setState(() => _selectedWallet = 'easypaisa'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Wallet Mobile Number',
          controller: _walletMobileController,
          prefixIcon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _walletChip({
    required String name,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.radiumSoft : AppColors.input,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.radium : AppColors.hairline,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.radium : AppColors.luminous,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpView() {
    return Column(
      key: const ValueKey('otp_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.radiumSoft,
              border: Border.all(color: AppColors.radium, width: 1.2),
            ),
            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.radium, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PayFast OTP Verification',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.luminous,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the one-time passcode to authenticate this transaction.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.dim, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PlacardLabel('ONE-TIME CODE', size: 9.5, color: AppColors.faint),
            GestureDetector(
              onTap: () {
                _otpController.text = '1234';
                setState(() {});
              },
              child: const Text(
                'Fill Test OTP (1234)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.radium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppTextField(
          label: 'Enter OTP',
          controller: _otpController,
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Confirm & Complete Payment',
          icon: Icons.check_circle_outline_rounded,
          onPressed: _busy ? null : _submitOtp,
          busy: _busy,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: _busy ? null : () => setState(() => _inOtpStep = false),
            child: const Text(
              'Back to Payment Details',
              style: TextStyle(color: AppColors.dim, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
