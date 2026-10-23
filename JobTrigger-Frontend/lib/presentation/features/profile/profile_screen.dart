import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/platform/package_info_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/auth/auth_state.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import '../auth/auth_notifier.dart';
import '../../../data/credentials/active_github_credential_notifier.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/credentials_notifier.dart';
import '../../../data/credentials/github_credentials_notifier.dart';
import '../tool_selection/active_tool_notifier.dart';
import '../tool_selection/ci_tool.dart';
import '../app_lock/app_lock_settings_section.dart';
import 'account_dialogs.dart';

/// Ported from `ProfileView.swift`, laid out to the P14 design
/// (`UI-UX/screens/10-profile`). The old app's "Change Password" row was a
/// "coming soon" placeholder; it's real since AUD-48, alongside account
/// deletion (App Store 5.1.1(v), Google Play's data-deletion policy).
///
/// Since P14-11 this is also where the app lock is set (it moved from
/// Settings with the redesign) and where the CI tool is switched.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).value;
    final email = authState is Authenticated ? authState.user.email : '';
    final activeTool = ref.watch(activeToolNotifierProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              16 + glassNavBarClearance(context),
            ),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.primary,
                    child: ExcludeSemantics(
                      child: Text(
                        email.isEmpty ? '?' : email[0].toUpperCase(),
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _sessionSummary(ref, activeTool),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const GroupHeader(title: 'Workspace'),
              GroupedCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: const Text('CI tool'),
                    trailing: _Trailing(
                      activeTool?.displayName ?? CiTool.jenkins.displayName,
                    ),
                    onTap: () => context.go(AppRoutes.toolSelection),
                  ),
                  ListTile(
                    leading: Icon(
                      activeTool == CiTool.githubActions
                          ? Icons.vpn_key_outlined
                          : Icons.dns_outlined,
                    ),
                    title: Text(
                      activeTool == CiTool.githubActions
                          ? 'Credential'
                          : 'Server',
                    ),
                    trailing: _Trailing(_activeName(ref, activeTool)),
                    onTap: () => context.go(AppRoutes.settings),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const AppLockSettingsSection(),
              const SizedBox(height: 16),
              const GroupHeader(title: 'Account'),
              GroupedCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: const Text('Change password'),
                    trailing: const _Chevron(),
                    onTap: () => _changePassword(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About JobTrigger'),
                    trailing: const _Chevron(),
                    onTap: () => context.push(AppRoutes.appInfo),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GroupedCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Log out'),
                    onTap: () =>
                        ref.read(authNotifierProvider.notifier).logout(),
                  ),
                  // AUD-26: revoke every session, e.g. after losing a phone.
                  ListTile(
                    leading: const Icon(Icons.devices_other_outlined),
                    title: const Text('Log out of all devices'),
                    onTap: () => _logoutEverywhere(context, ref),
                  ),
                  // AUD-48: permanent, so it's last and asks for the
                  // password.
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: t.failure.foreground,
                    ),
                    title: Text(
                      'Delete account',
                      style: TextStyle(color: t.failure.foreground),
                    ),
                    onTap: () => _deleteAccount(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                packageInfoAsync.when(
                  data: (info) =>
                      'Version ${info.version} (${info.buildNumber})',
                  loading: () => '',
                  error: (error, stackTrace) => '',
                ),
                textAlign: TextAlign.center,
                style: AppTypography.mono(textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Acme production · 2 servers" — what this account has set up for the
  /// tool in use.
  String _sessionSummary(WidgetRef ref, CiTool? activeTool) {
    if (activeTool == CiTool.githubActions) {
      final count = ref.watch(gitHubCredentialsNotifierProvider).value?.length;
      return [
        ?ref.watch(activeGitHubCredentialNotifierProvider)?.label,
        // Only once known: "0" while the list loads would be wrong.
        if (count != null)
          count == 1 ? '1 GitHub credential' : '$count GitHub credentials',
      ].join(' · ');
    }
    final count = ref.watch(credentialsNotifierProvider).value?.length;
    return [
      ?ref.watch(activeServerNotifierProvider)?.serverName,
      if (count != null) count == 1 ? '1 server' : '$count servers',
    ].join(' · ');
  }

  String _activeName(WidgetRef ref, CiTool? activeTool) =>
      (activeTool == CiTool.githubActions
          ? ref.watch(activeGitHubCredentialNotifierProvider)?.label
          : ref.watch(activeServerNotifierProvider)?.serverName) ??
      'None';

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final toast = ref.read(toastControllerProvider);
    final changed = await showChangePasswordDialog(
      context,
      onSubmit: (values) async {
        final problem = await ref
            .read(authNotifierProvider.notifier)
            .changePassword(
              currentPassword: values[0],
              newPassword: values[1],
              confirmPassword: values[2],
            );
        return problem == null ? null : describeError(problem);
      },
    );
    if (!changed) return;
    toast.show(
      type: ToastType.success,
      title: 'Password changed',
      message: 'Other devices were signed out.',
    );
  }

  /// A successful deletion signs out, which leaves this screen; the login
  /// screen is where the user lands.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    await showDeleteAccountDialog(
      context,
      onSubmit: (values) async {
        final problem = await ref
            .read(authNotifierProvider.notifier)
            .deleteAccount(values[0]);
        return problem == null ? null : describeError(problem);
      },
    );
  }

  Future<void> _logoutEverywhere(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Log out of all devices?',
      message:
          'Every device signed in to this account, including this one, '
          'will need to log in again.',
      confirmLabel: 'Log out everywhere',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    // Read before the await: a successful logout leaves this screen.
    final toast = ref.read(toastControllerProvider);
    final failure = await ref
        .read(authNotifierProvider.notifier)
        .logoutEverywhere();
    if (failure == null) return;
    toast.show(
      type: ToastType.error,
      title: "Couldn't log out everywhere",
      message: failure.message,
    );
  }
}

/// A row's current value, with a chevron: it opens where that's changed.
class _Trailing extends StatelessWidget {
  const _Trailing(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      const _Chevron(),
    ],
  );
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right_rounded,
    size: 20,
    color: AppTokens.of(context).textMuted,
  );
}
