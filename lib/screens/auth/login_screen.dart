import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_config.dart';
import '../../constants/app_strings.dart';
import '../../services/service_locator.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/mark_widgets.dart';
import '../../widgets/placard_label.dart';
import '../splash/splash_screen.dart';

/// Sign-in window. Instrument-style inputs, inline red lamp errors, and a
/// one-tap demo account fill for reviewers.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = Validators.email(_email.text);
    final passwordError = Validators.password(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = null;
    });
    if (emailError != null || passwordError != null) return;

    setState(() => _busy = true);
    try {
      await Services.auth.login(_email.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.home);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fillDemo() {
    setState(() {
      _email.text = AppConfig.demoEmail;
      _password.text = AppConfig.demoPassword;
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panel,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(size: 34),
                    const SizedBox(height: 44),
                    const Text(
                      AppStrings.signIn,
                      style: TextStyle(
                        color: AppColors.luminous,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.signInSubtitle,
                      style: const TextStyle(color: AppColors.dim, fontSize: 13.5),
                    ),
                    const SizedBox(height: 30),
                    AppTextField(
                      label: AppStrings.email,
                      controller: _email,
                      errorText: _emailError,
                      onChanged: (_) => setState(() => _formError = null),
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.alternate_email_rounded,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: AppStrings.password,
                      controller: _password,
                      obscure: _obscure,
                      errorText: _passwordError,
                      onChanged: (_) => setState(() => _formError = null),
                      prefixIcon: Icons.lock_outline_rounded,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                          color: AppColors.faint,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 16),
                      ErrorBanner(
                        message: _formError!,
                        onDismiss: () => setState(() => _formError = null),
                      ),
                    ],
                    const SizedBox(height: 26),
                    PrimaryButton(
                      label: AppStrings.signInButton,
                      onPressed: _busy ? null : _submit,
                      busy: _busy,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.hairline, height: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: PlacardLabel(AppStrings.demoHint, size: 8.5, spacing: 1),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.hairline,
                            height: 1,
                            indent: 0,
                            endIndent: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _fillDemo,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.radium,
                          minimumSize: const Size(0, 44),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                        child: const Text(AppStrings.useDemo),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '${AppStrings.noAccount}  ',
                          style: TextStyle(color: AppColors.dim, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed(Routes.register),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.radium,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text(AppStrings.createButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
