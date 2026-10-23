import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/auth/auth_validation.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/loading_overlay.dart';
import '../../common_widgets/pinned_footer_layout.dart';
import '../../navigation/app_routes.dart';
import 'signup_notifier.dart';

/// Ported from `Features/Auth/SignupView.swift`, laid out to the P14
/// design (`UI-UX/screens/02-signup`). The strength meter and the "don't
/// match" hint update as the user types; the rules that decide whether
/// the form can be sent stay in [SignupNotifier], and a refusal is shown
/// inline above the form like the login screen's.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Redraws the meter and the match hint as the user types.
    _passwordController.addListener(_redraw);
    _confirmPasswordController.addListener(_redraw);
  }

  void _redraw() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _back() => Navigator.of(context).canPop()
      ? Navigator.of(context).pop()
      : context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final signup = ref.watch(signupNotifierProvider);
    final isLoading = signup.isLoading;
    final error = switch (signup) {
      AsyncError(:final error) => describeError(error),
      _ => null,
    };
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final password = _passwordController.text;
    final mismatch = !AuthValidation.passwordsMatch(
      password,
      _confirmPasswordController.text,
    );

    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: isLoading,
          child: PinnedFooterLayout(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(-12, 0),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back to log in',
                      onPressed: _back,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Create your account', style: textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Your Jenkins and GitHub credentials stay encrypted, '
                  'tied to this account.',
                  style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: 28),
                if (error != null) ...[
                  InlineAlert(message: error, liveRegion: true),
                  const SizedBox(height: 16),
                ],
                LabeledField(
                  label: 'Email',
                  child: TextField(
                    key: const Key('signup_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'you@company.com',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Password',
                  child: TextField(
                    key: const Key('signup_password_field'),
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                  ),
                ),
                const SizedBox(height: 10),
                _StrengthMeter(password: password),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Confirm password',
                  child: TextField(
                    key: const Key('signup_confirm_field'),
                    controller: _confirmPasswordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      errorText: mismatch ? 'Passwords don’t match.' : null,
                    ),
                  ),
                ),
              ],
            ),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: const Key('signup_submit_button'),
                  onPressed: isLoading ? null : _submit,
                  child: const Text('Create account'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: t.textMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: _back,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    ref
        .read(signupNotifierProvider.notifier)
        .signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
  }
}

/// Four segments filling with [AuthValidation.passwordStrength], and the
/// word for it underneath. The segments are decoration; the word is what a
/// screen reader announces.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final strength = AuthValidation.passwordStrength(password);
    const min = AuthValidation.minPasswordLength;
    final (label, tone) = switch (strength) {
      _ when password.isEmpty => ('At least $min characters', null),
      0 => ('Too short — at least $min characters', StatusTone.failure),
      1 => (
        'Fair — longer, or mix in numbers and symbols',
        StatusTone.unstable,
      ),
      2 => ('Good', StatusTone.success),
      3 => ('Strong', StatusTone.success),
      _ => ('Very strong', StatusTone.success),
    };
    final fill = tone == null ? t.raised : t.status(tone).dot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < AuthValidation.maxPasswordStrength; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < strength || (strength == 0 && i == 0)
                          ? fill
                          : t.raised,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tone == null ? t.textMuted : t.status(tone).foreground,
          ),
        ),
      ],
    );
  }
}
