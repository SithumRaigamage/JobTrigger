import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/app_logo.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/labeled_field.dart';
import '../../common_widgets/loading_overlay.dart';
import '../../common_widgets/pinned_footer_layout.dart';
import '../../navigation/app_routes.dart';
import 'login_notifier.dart';
import 'remembered_email_notifier.dart';

/// Ported from `Features/Auth/LoginView.swift`, laid out to the P14 design
/// (`UI-UX/screens/01-login`). A failed login is shown inline above the
/// form, where the user is looking, rather than as a toast. Navigation on
/// success is left to `app_router.dart`'s redirect reacting to
/// `authNotifierProvider`, not driven from here.
///
/// Responsive: below [_wideBreakpoint] (phones) the form fills the screen
/// with the button at the bottom. At or above it (macOS window, iPad
/// landscape) a branding panel takes the left side.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _wideBreakpoint = 900.0;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  /// Prefill from [rememberedEmailNotifierProvider] exactly once, when it
  /// first resolves — never again, so it can't overwrite what the user has
  /// since typed.
  bool _prefilled = false;

  void _prefillRememberedEmail(String? email) {
    if (_prefilled) return;
    _prefilled = true;
    if (email == null) return;
    setState(() {
      _emailController.text = email;
      _rememberMe = true;
    });
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(rememberedEmailNotifierProvider, (previous, next) {
      if (next case AsyncData(:final value)) _prefillRememberedEmail(value);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginNotifierProvider);
    final isLoading = login.isLoading;
    final error = switch (login) {
      AsyncError(:final error) => describeError(error),
      _ => null,
    };

    Widget form({required bool showLogo}) => PinnedFooterLayout(
      body: _LoginForm(
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        onToggleObscure: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        rememberMe: _rememberMe,
        onRememberMeChanged: (value) => setState(() => _rememberMe = value),
        error: error,
        onSubmit: _submit,
        showLogo: showLogo,
      ),
      footer: _LoginActions(
        isLoading: isLoading,
        onSignIn: _submit,
        onSignUp: () => context.go(AppRoutes.signup),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: isLoading,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _wideBreakpoint) {
                return form(showLogo: true);
              }
              return Row(
                children: [
                  const Expanded(flex: 5, child: _BrandingPanel()),
                  Expanded(flex: 4, child: form(showLogo: false)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    unawaited(
      ref
          .read(loginNotifierProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          ),
    );
  }
}

/// Left-hand panel shown only on wide (macOS / desktop / tablet) layouts —
/// fills the space that would otherwise just be background, and doubles as
/// light marketing copy for what the app does.
class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel();

  static const _features = [
    (
      Icons.play_circle_outline,
      'Trigger builds',
      'With or without parameters, in a couple taps',
    ),
    (
      Icons.monitor_heart_outlined,
      'Live status',
      'Real-time progress and health for every job',
    ),
    (
      Icons.terminal,
      'Stream logs',
      'Console output as it happens, no waiting for it to finish',
    ),
    (
      Icons.dns_outlined,
      'Multi-server',
      'Switch between Jenkins instances instantly',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 48, 40, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'JobTrigger',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Trigger and monitor Jenkins\nbuilds from anywhere.',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            for (final f in _features)
              _FeatureRow(icon: f.$1, title: f.$2, subtitle: f.$3),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: onPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: onPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.error,
    required this.onSubmit,
    required this.showLogo,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;

  /// The last attempt's failure, already worded for the user.
  final String? error;
  final VoidCallback onSubmit;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLogo) ...[
          const Align(alignment: Alignment.centerLeft, child: AppLogo()),
          const SizedBox(height: 18),
        ],
        Text('Welcome back', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Log in to trigger and watch your builds.',
          style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
        ),
        const SizedBox(height: 32),
        if (error != null) ...[
          InlineAlert(message: error!, liveRegion: true),
          const SizedBox(height: 16),
        ],
        LabeledField(
          label: 'Email',
          child: TextField(
            key: const Key('login_email_field'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'you@company.com'),
          ),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Password',
          child: TextField(
            key: const Key('login_password_field'),
            controller: passwordController,
            obscureText: obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              suffixIcon: IconButton(
                // AUD-62: an icon-only button needs an accessible name --
                // `labeledTapTargetGuideline` rejects a tappable node with no
                // semantic label, and a screen reader has nothing to announce.
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remember my email'),
          value: rememberMe,
          onChanged: onRememberMeChanged,
        ),
      ],
    );
  }
}

class _LoginActions extends StatelessWidget {
  const _LoginActions({
    required this.isLoading,
    required this.onSignIn,
    required this.onSignUp,
  });

  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = AppTokens.of(context).textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('login_submit_button'),
          onPressed: isLoading ? null : onSignIn,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Text('Log in'),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'New to JobTrigger?',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 14, color: muted),
            ),
            TextButton(
              onPressed: onSignUp,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ],
    );
  }
}
