import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/service_locator.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/mark_widgets.dart';
import '../../widgets/placard_label.dart';
import '../splash/splash_screen.dart';

/// Registration window. Validates inline, creates the mock account and
/// signs the user straight into the panel.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameError = Validators.name(_name.text);
    final emailError = Validators.email(_email.text);
    final passwordError = Validators.password(_password.text);
    final confirmError =
        Validators.confirmPassword(_confirm.text, _password.text);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _formError = null;
    });
    if ([nameError, emailError, passwordError, confirmError]
        .any((e) => e != null)) {
      return;
    }

    setState(() => _busy = true);
    try {
      await Services.auth.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.home);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
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
        centerTitle: false,
        title: const PlacardLabel('NEW PANEL', size: 11, spacing: 2.4, color: AppColors.dim),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.createAccount,
                      style: TextStyle(
                        color: AppColors.luminous,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.createAccountSubtitle,
                      style: TextStyle(color: AppColors.dim, fontSize: 13.5),
                    ),
                    const SizedBox(height: 30),
                    AppTextField(
                      label: AppStrings.fullName,
                      controller: _name,
                      errorText: _nameError,
                      onChanged: (_) => setState(() => _formError = null),
                      prefixIcon: Icons.person_outline_rounded,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
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
                      onChanged: (_) => setState(() {
                            _formError = null;
                            _confirmError = null;
                          }),
                      prefixIcon: Icons.lock_outline_rounded,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 18),
                    AppTextField(
                      label: AppStrings.confirmPassword,
                      controller: _confirm,
                      obscure: _obscure,
                      errorText: _confirmError,
                      onChanged: (_) => setState(() {
                            _formError = null;
                            _confirmError = null;
                          }),
                      prefixIcon: Icons.lock_outline_rounded,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
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
                      label: AppStrings.createButton,
                      onPressed: _busy ? null : _submit,
                      busy: _busy,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '${AppStrings.haveAccount}  ',
                          style: TextStyle(color: AppColors.dim, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.radium,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text(AppStrings.signInButton),
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
