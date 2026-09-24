import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payment_system/firebase/firebase_bootstrap.dart';
import 'package:payment_system/main.dart';
import 'package:payment_system/models/payfast_config.dart';
import 'package:payment_system/services/payfast_service.dart';
import 'package:payment_system/utils/formatters.dart';

void main() {
  test('Firebase bootstrap degrades gracefully without config', () async {
    // In a test environment no google-services config exists: the probe
    // must fail softly and leave the app in simulated mode.
    await FirebaseBootstrap.initialize();
    expect(FirebaseBootstrap.configured, isFalse);
  });

  group('Formatters', () {
    test('currency groups thousands without decimals', () {
      expect(Formatters.currency(5000), 'PKR 5,000');
      expect(Formatters.currency(0), 'PKR 0');
      expect(Formatters.currency(8900), 'PKR 8,900');
    });

    test('signedAmount renders ledger signs', () {
      expect(Formatters.signedAmount(5000), '+5,000');
      expect(Formatters.signedAmount(-100), '-100');
    });

    test('shortDateTime composes day, month and time', () {
      final dt = DateTime(2026, 8, 12, 15, 42);
      expect(Formatters.shortDateTime(dt), '12 Aug · 3:42 PM');
    });
  });

  group('parseAmount', () {
    test('accepts whole PKR amounts', () {
      final ok = parseAmount('2,500');
      expect(ok.valid, isTrue);
      expect(ok.value, 2500);
    });

    test('rejects decimals, zero and junk', () {
      expect(parseAmount('12.5').valid, isFalse);
      expect(parseAmount('0').valid, isFalse);
      expect(parseAmount('abc').valid, isFalse);
    });
  });

  group('App shell', () {
    testWidgets('boots to the sign-in window when no session exists',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const PaymentApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Access your wallet panel'), findsOneWidget);
      expect(find.text('Recharge wallet'), findsNothing);
    });

    testWidgets('dashboard is reachable after a simulated login',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const PaymentApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Use demo account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Recharge wallet'), findsOneWidget);
      expect(find.text('WALLET BALANCE'), findsOneWidget);
    });
  });

  group('PayFast Gateway Integration', () {
    test('PayFastConfig loads defaults and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final config = await PayFastConfig.load();
      expect(config.merchantId, '14833');
      expect(config.environment, PayFastEnvironment.sandbox);
      expect(config.isEnabled, isTrue);

      config.merchantId = 'MERCHANT-TEST-99';
      config.isEnabled = true;
      await config.save();

      final reloaded = await PayFastConfig.load();
      expect(reloaded.merchantId, 'MERCHANT-TEST-99');
      expect(reloaded.isEnabled, isTrue);
    });

    test('PayFastService processes card payment and verifies OTP', () async {
      final service = PayFastService();
      final cardRes = await service.processCardPayment(
        amount: 5000,
        basketId: 'BASKET-12345',
        cardNumber: '4111 1111 1111 1111',
        expiryMonth: '12',
        expiryYear: '28',
        cvv: '123',
        customerEmail: 'test@gopayfast.com',
        customerMobile: '03001234567',
      );

      expect(cardRes.success, isTrue);
      expect(cardRes.requiresOtp, isTrue);

      final otpRes = await service.verifyOtp(
        transactionId: cardRes.transactionId,
        otp: '1234',
      );

      expect(otpRes.success, isTrue);
      expect(otpRes.status, 'SUCCESS');
    });

    test('PayFastService rejects invalid OTP code', () async {
      final service = PayFastService();
      final otpRes = await service.verifyOtp(
        transactionId: 'BASKET-FAIL',
        otp: '9999',
      );

      expect(otpRes.success, isFalse);
    });
  });
}

