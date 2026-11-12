import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/auth/auth_validation.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/loading_overlay.dart';
import '../../common_widgets/pinned_footer_layout.dart';
import '../../navigation/app_routes.dart';
import 'reset_password_notifier.dart';

/// US-AUTH-08: opened from the emailed link
/// (`jobtrigger://app/reset-password?token=…`), signed in or not. Three
/// states: a malformed link, the new-password form, and done.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_redraw);
  }

  void _redraw() => setState(() {});

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() => unawaited(
    ref
        .read(resetPasswordNotifierProvider.notifier)
        .resetPassword(
          token: widget.token,
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
        ),
  );

  @override
  Widget build(BuildContext context) {
    final reset = ref.watch(resetPasswordNotifierProvider);
    final isLoading = reset.isLoading;
    final done = reset.value ?? false;
    final wellFormed = ResetPasswordNotifier.isWellFormedToken(widget.token);
    final error = switch (reset) {
      AsyncError(:final error) => describeError(error),
      _ => null,
    };
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final mismatch = !AuthValidation.passwordsMatch(
      _passwordController.text,
      _confirmController.text,
    );

    final (title, message) = switch ((wellFormed, done)) {
      (false, _) => (
        'This link doesn’t work',
        'It may be incomplete, used already, or expired. Ask for a new one '
            'from the log in screen.',
      ),
      (true, true) => (
        'Password reset',
        'You’ve been signed out on every device. Log in with your new '
            'password.',
      ),
      (true, false) => (
        'Choose a new password',
        'At least ${AuthValidation.minPasswordLength} characters. Resetting '
            'signs you out on every device.',
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: isLoading,
          child: PinnedFooterLayout(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: textTheme.headlineLarge),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: 28),
                if (error != null) ...[
                  InlineAlert(message: error, liveRegion: true),
                  const SizedBox(height: 16),
                ],
                if (wellFormed && !done) ...[
                  LabeledField(
                    label: 'New password',
                    child: TextField(
                      key: const Key('reset_password_field'),
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    label: 'Confirm new password',
                    child: TextField(
                      key: const Key('reset_confirm_field'),
                      controller: _confirmController,
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
              ],
            ),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wellFormed && !done)
                  FilledButton(
                    key: const Key('reset_submit_button'),
                    onPressed: isLoading ? null : _submit,
                    child: const Text('Reset password'),
                  )
                else
                  FilledButton(
                    key: const Key('reset_go_to_login'),
                    onPressed: () => context.go(
                      wellFormed ? AppRoutes.login : AppRoutes.forgotPassword,
                    ),
                    child: Text(wellFormed ? 'Log in' : 'Ask for a new link'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
