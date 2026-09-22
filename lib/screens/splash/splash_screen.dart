import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../constants/app_strings.dart';
import '../../services/service_locator.dart';
import '../../widgets/gauge_mark.dart';
import '../../widgets/placard_label.dart';

/// Power-on sequence: the gauge sweeps its needle while the session
/// restores, then routes to the panel (or the sign-in window).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _needle = -120;
  double _reveal = 0;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _needle = 120);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _reveal = 1);

    await Future<void>.delayed(AppConfig.splashDuration);
    if (!mounted) return;
    await Services.auth.restoreSession();
    if (!mounted) return;
    if (!Services.auth.isSignedIn) {
      Navigator.of(context).pushReplacementNamed(Routes.login);
    } else if (Services.auth.isPhoneVerified) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.verifyPhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _needle),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, needle, _) {
            return AnimatedOpacity(
              opacity: _reveal,
              duration: const Duration(milliseconds: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GaugeMark(size: 104, needle: needle),
                  const SizedBox(height: 26),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: AppColors.luminous,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const PlacardLabel(
                    AppStrings.appTagline,
                    size: 10.5,
                    spacing: 3,
                    color: AppColors.faint,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Route names shared by the app and the splash navigator.
abstract final class Routes {
  static const login = '/login';
  static const register = '/register';
  static const verifyPhone = '/verify-phone';
  static const home = '/home';
  static const recharge = '/recharge';
  static const history = '/history';
  static const profile = '/profile';
  static const settings = '/settings';
}
