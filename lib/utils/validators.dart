import 'package:flutter/services.dart';
import '../constants/app_strings.dart';

/// Field validators shared by auth and recharge forms.
abstract final class Validators {
  static final RegExp _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return AppStrings.errEmailRequired;
    if (!_emailRe.hasMatch(v)) return AppStrings.errEmailInvalid;
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return AppStrings.errPasswordRequired;
    if (v.length < 6) return AppStrings.errPasswordShort;
    return null;
  }

  static String? name(String? value) {
    if ((value?.trim() ?? '').isEmpty) return AppStrings.errNameRequired;
    return null;
  }

  static String? confirmPassword(String? confirm, String? original) =>
      confirm == original ? null : AppStrings.errConfirmMismatch;

  /// Whole rupees only, within [AppConfig.minAmount, maxAmount].
  static String? amount(String? value) {
    final v = (value ?? '').trim().replaceAll(',', '');
    final parsed = int.tryParse(v);
    if (parsed == null || parsed <= 0) return AppStrings.errAmountInvalid;
    if (parsed > 1000000) return AppStrings.errAmountInvalid;
    return null;
  }
}

/// Restricts custom amount input to digits only.
final List<TextInputFormatter> amountFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
  LengthLimitingTextInputFormatter(9),
];
