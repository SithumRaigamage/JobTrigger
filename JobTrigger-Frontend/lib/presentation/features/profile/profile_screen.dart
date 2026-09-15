import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/package_info_provider.dart';
import '../../../domain/auth/auth_state.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import '../auth/auth_notifier.dart';
import '../settings/active_server_notifier.dart';
import '../settings/credentials_notifier.dart';

/// Ported from `ProfileView.swift`. Deliberately skips the old app's
/// "Change Password" / "Security Settings" rows — both were unimplemented
/// "coming soon" placeholders with no backend support (no password-change
/// route exists in `JobTrigger-Backend`), so there's no real feature there
/// to preserve; flagged rather than silently ported as dead UI.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).value;
    final email = authState is Authenticated ? authState.user.email : '';
    final activeServer = ref.watch(activeServerNotifierProvider);
    final serversCount =
        ref.watch(credentialsNotifierProvider).value?.length ?? 0;
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Tool Selection',
          onPressed: () => context.go(AppRoutes.toolSelection),
        ),
        title: const Text('Profile'),
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
            16,
            16 + glassNavBarClearance(context),
          ),
          children: [
            Icon(
              Icons.account_circle,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Active User',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            GlassSurface.card(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CURRENT SESSION',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Active Server'),
                    trailing: Text(activeServer?.serverName ?? 'None'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Server URL'),
                    trailing: SizedBox(
                      width: 180,
                      child: Text(
                        activeServer?.jenkinsURL ?? '—',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('Saved Servers'),
                    trailing: Text('$serversCount'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassSurface.card(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'APP INFORMATION',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    trailing: Text(
                      packageInfoAsync.when(
                        data: (info) =>
                            '${info.version} (${info.buildNumber})',
                        loading: () => '…',
                        error: (error, stackTrace) => '—',
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('App Information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.appInfo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.tonal(
                // Explicit colors instead of FilledButton.tonal's default
                // (secondaryContainer/onSecondaryContainer) -- this
                // ColorScheme.light() doesn't define secondaryContainer,
                // so it fell back to a dark, near-black tone that read as
                // a jarring "grey" block instead of a clear destructive
                // action.
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.1),
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
