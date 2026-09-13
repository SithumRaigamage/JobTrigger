import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/error_message.dart';
import '../../../core/platform/package_info_provider.dart';
import '../../common_widgets/loading_overlay.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import 'login_notifier.dart';

/// Ported from `Features/Auth/LoginView.swift`. Errors surface as a toast
/// (matching the original's `NotificationManager` usage) rather than inline
/// field text — actual navigation on success is left to `app_router.dart`'s
/// redirect reacting to `authNotifierProvider`, not driven from here.
///
/// Responsive: below [_wideBreakpoint] (phones, most iOS/Android) this is a
/// single centered card over a softly tinted backdrop. At or above it
/// (macOS window, iPad landscape, desktop browser) it splits into a left
/// branding/feature panel and a right form panel, so the extra horizontal
/// space is used instead of just padding out a centered card.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _wideBreakpoint = 900.0;
  static const _savedEmailKey = 'login_saved_email';
  static const _savedPasswordKey = 'login_saved_password';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_savedEmailKey);
      final password = prefs.getString(_savedPasswordKey);
      if (email != null) {
        _emailController.text = email;
        _rememberMe = true;
      }
      if (password != null) {
        _passwordController.text = password;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveCredentialsIfNeeded() async {
    if (_rememberMe) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_savedEmailKey, _emailController.text.trim());
        await prefs.setString(_savedPasswordKey, _passwordController.text);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginNotifierProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.warning,
              title: 'Login Failed',
              message: describeError(error),
            );
      }
    });

    final isLoading = ref.watch(loginNotifierProvider).isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _GradientBackdrop(
        color: colorScheme.primary,
        background: colorScheme.surface,
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: isLoading,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= _wideBreakpoint;
                if (isWide) {
                  return Row(
                    children: [
                      const Expanded(flex: 5, child: _BrandingPanel()),
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 32,
                            ),
                            child: _LoginForm(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              rememberMe: _rememberMe,
                              onRememberMeChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              isLoading: isLoading,
                              onSignIn: _submit,
                              onSignUp: () => context.go(AppRoutes.signup),
                              showLogo: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _LoginForm(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        rememberMe: _rememberMe,
                        onRememberMeChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                        isLoading: isLoading,
                        onSignIn: _submit,
                        onSignUp: () => context.go(AppRoutes.signup),
                        showLogo: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    await _saveCredentialsIfNeeded();
    ref
        .read(loginNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }
}

/// [background] with two softly tinted [color] blobs — enough to keep the
/// screen from feeling flat without hardcoding a color that would fight the
/// active theme (light surfaces stay white, dark surfaces stay dark).
class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop({
    required this.color,
    required this.background,
    required this.child,
  });

  final Color color;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: background),
        Positioned(
          top: -120,
          right: -80,
          child: _Blob(color: color.withValues(alpha: 0.08), size: 320),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _Blob(color: color.withValues(alpha: 0.06), size: 360),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
                    Icons.shield_outlined,
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
    required this.isLoading,
    required this.onSignIn,
    required this.onSignUp,
    required this.showLogo,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: colorScheme.onPrimary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'JobTrigger',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
        ] else ...[
          Text(
            'Welcome back',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          'Sign in to manage your Jenkins builds',
          textAlign: showLogo ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'email@example.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Required',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remember me'),
          value: rememberMe,
          onChanged: onRememberMeChanged,
          dense: true,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton(
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
                : const Text('Sign In'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onSignUp,
            child: const Text("Don't have an account? Sign Up"),
          ),
        ),
        const SizedBox(height: 28),
        const _PlatformFooter(),
      ],
    );
  }
}

/// Small "works everywhere" strip — cheap way to make the empty space below
/// the button feel intentional instead of cut off.
class _PlatformFooter extends ConsumerWidget {
  const _PlatformFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final packageInfo = ref.watch(packageInfoProvider);

    return Column(
      children: [
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            _PlatformChip(icon: Icons.phone_iphone, label: 'iOS'),
            _PlatformChip(icon: Icons.android, label: 'Android'),
            _PlatformChip(icon: Icons.laptop_mac, label: 'macOS'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          // Blank while unresolved rather than repeating "JobTrigger" (the
          // headline above already shows it) -- avoids two identical
          // "JobTrigger" texts on screen at once before the real version
          // loads.
          packageInfo.when(
            data: (info) => 'v${info.version}',
            loading: () => '',
            error: (_, _) => '',
          ),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
