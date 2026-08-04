import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/transactions/transaction_history_screen.dart';
import 'screens/wallet/recharge_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
// DIRECTION CONTRACT — night-flight instrument panel
//
// THESIS: a digital wallet that reads like a flight instrument at night.
// Money is a reading, not a decoration; the app refuses the bright,
// card-stack fintech default and instead trusts luminous digits on a
// matte black panel.
//
// OWN-WORLD: matte black panel ground (#0A0D11); instrument faces in
// raised charcoal with hairline divisions; luminous white markings for
// every label and figure; radium-green for live values and the primary
// action; amber and red reserved for caution and failure only; tabular
// numerals everywhere money is shown.
//
// STORY: the visitor powers on, sees the gauge sweep, signs in, and
// reads their balance as the primary instrument. Recharging runs a
// three-stage cross-check (create → confirm → verify) and only then
// does the balance needle move. Failure keeps the balance untouched —
// exactly how server-side verification behaves.
//
// FIRST VIEWPORT: splash — gauge needle sweeps from -120° to 120° on a
// hairline ring, name + placard rise in. Then the wallet dashboard:
// gauge mark and owner ring above, balance as a full-width instrument
// face (placard + LIVE lamp + 46pt tabular digits), two supporting
// readouts (total recharged, transaction count), the radium RECHARGE
// control, and the recent-activity cross-check below.
//
// FORM: aviation instrument six-pack grammar; the gauge mark is the
// logo, placards are labels, lamps are status, lists read like cross-
// checks. Seed: 83680673.
//
// FINISH: unreviewed and undocumented is unfinished; this build ends
// with the finish review, the verdict, and DESIGN.md.
// ═══════════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.panel,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PaymentApp());
}

class PaymentApp extends StatelessWidget {
  const PaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.register: (_) => const RegisterScreen(),
        Routes.home: (_) => const HomeScreen(),
        Routes.recharge: (_) => const RechargeScreen(),
        Routes.history: (_) => const TransactionHistoryScreen(),
        Routes.profile: (_) => const ProfileScreen(),
        Routes.settings: (_) => const SettingsScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AppColors.scheme,
      scaffoldBackgroundColor: AppColors.panel,
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.luminous,
            displayColor: AppColors.luminous,
          )
          .copyWith(
            bodyMedium: const TextStyle(
              color: AppColors.luminous,
              fontSize: 14,
              height: 1.4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            titleLarge: const TextStyle(
              color: AppColors.luminous,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.luminous,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: TextStyle(color: AppColors.luminous, fontSize: 12.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.hairlineBright),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.radiumSoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: states.contains(WidgetState.selected)
                ? AppColors.radium
                : AppColors.dim,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.radium
                : AppColors.dim,
            size: 24,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.radium,
          foregroundColor: AppColors.radiumDeep,
          disabledBackgroundColor: AppColors.hairline,
          disabledForegroundColor: AppColors.faint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
