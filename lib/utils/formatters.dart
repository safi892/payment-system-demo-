import 'package:flutter/material.dart';

/// Formatting helpers. Money reads like instrument data: tabular digits,
/// whole rupees, thin group separators.
abstract final class Formatters {
  static const String _currency = 'PKR';

  /// "PKR 5,000" — whole rupees, grouped.
  static String currency(num amount) => '$_currency ${_grouped(amount.round())}';

  /// "5,000" — digits only, for dense readouts.
  static String amount(num amount) => _grouped(amount.round());

  /// "+5,000" / "-100" with an explicit sign for ledger entries.
  static String signedAmount(num amount) {
    final sign = amount < 0 ? '-' : '+';
    return '$sign${_grouped(amount.abs().round())}';
  }

  /// "12 AUG 2026"
  static String date(DateTime dt) =>
      '${dt.day} ${_monthAbbr(dt.month)} ${dt.year}'.toUpperCase();

  /// "12 Aug · 3:42 PM"
  static String shortDateTime(DateTime dt) =>
      '${dt.day} ${_monthAbbr(dt.month)} · ${time(dt)}';

  /// "3:42 PM"
  static String time(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $meridiem';
  }

  /// "12 AUG 2026"
  static String monthYear(DateTime dt) => '${_monthAbbr(dt.month)} ${dt.year}'.toUpperCase();

  static String _grouped(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && (fromEnd - 1) % 3 == 0) buffer.write(',');
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }

  static String _monthAbbr(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  /// Text style that guarantees tabular figures for any money readout.
  static TextStyle tabular([TextStyle? base]) =>
      (base ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// A payable amount parsed from the custom field.
({bool valid, double? value, String? error}) parseAmount(String input) {
  final trimmed = input.trim().replaceAll(',', '');
  final parsed = double.tryParse(trimmed);
  if (parsed == null || parsed <= 0 || parsed != parsed.roundToDouble()) {
    return (valid: false, value: null, error: 'Enter a whole PKR amount');
  }
  if (parsed > 1000000) {
    return (valid: false, value: null, error: 'Maximum is PKR 1,000,000');
  }
  return (valid: true, value: parsed, error: null);
}
