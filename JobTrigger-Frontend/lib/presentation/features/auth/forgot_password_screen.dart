import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/loading_overlay.dart';
import '../../common_widgets/pinned_footer_layout.dart';
import '../../navigation/app_routes.dart';
import 'forgot_password_notifier.dart';

/// US-AUTH-08: asks for the account email and sends a reset link. Laid out
/// like the signup screen (back chevron, heading, form, pinned button).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  /// Prefilled from the login form, so the user needn't type it twice.
  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _back() => Navigator.of(context).canPop()
      ? Navigator.of(context).pop()
      : context.go(AppRoutes.login);

  void _submit() => unawaited(
    ref
        .read(forgotPasswordNotifierProvider.notifier)
        .requestReset(_emailController.text.trim()),
  );

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(forgotPasswordNotifierProvider);
    final isLoading = request.isLoading;
    final sent = request.value ?? false;
    final error = switch (request) {
      AsyncError(:final error) => describeError(error),
      _ => null,
    };
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

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
                Semantics(
                  header: true,
                  child: Text(
                    sent ? 'Check your inbox' : 'Reset your password',
                    style: textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sent
                      ? 'If an account exists for '
                            '${_emailController.text.trim()}, we’ve sent it a '
                            'link to reset the password. The link works once '
                            'and expires in 15 minutes. Open it on this phone.'
                      : 'Enter the email you sign in with. We’ll send you a '
                            'link to choose a new password.',
                  style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: 28),
                if (error != null) ...[
                  InlineAlert(message: error, liveRegion: true),
                  const SizedBox(height: 16),
                ],
                if (!sent)
                  LabeledField(
                    label: 'Email',
                    child: TextField(
                      key: const Key('forgot_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'you@company.com',
                      ),
                    ),
                  ),
              ],
            ),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sent
                  ? [
                      FilledButton(
                        key: const Key('forgot_back_to_login'),
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Back to log in'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref
                            .read(forgotPasswordNotifierProvider.notifier)
                            .reset(),
                        child: const Text('Use a different email'),
                      ),
                    ]
                  : [
                      FilledButton(
                        key: const Key('forgot_submit_button'),
                        onPressed: isLoading ? null : _submit,
                        child: const Text('Send reset link'),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
