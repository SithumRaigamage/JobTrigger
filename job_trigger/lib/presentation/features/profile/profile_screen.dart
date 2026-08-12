import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/package_info_provider.dart';
import '../../../domain/auth/auth_state.dart';
import '../../navigation/app_routes.dart';
import '../auth/auth_notifier.dart';
import '../settings/active_server_notifier.dart';
import '../settings/credentials_notifier.dart';

/// Ported from `ProfileView.swift`. Deliberately skips the old app's
/// "Change Password" / "Security Settings" rows — both were unimplemented
/// "coming soon" placeholders with no backend support (no password-change
/// route exists in `lab-trigger-backend`), so there's no real feature there
/// to preserve; flagged rather than silently ported as dead UI.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).value;
    final email = authState is Authenticated ? authState.user.email : '';
    final activeServer = ref.watch(activeServerNotifierProvider);
    final serversCount = ref.watch(credentialsNotifierProvider).value?.length ?? 0;
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.account_circle, size: 80, color: Colors.blue),
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
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('CURRENT SESSION', style: TextStyle(fontSize: 12)),
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
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('APP INFORMATION', style: TextStyle(fontSize: 12)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text(
              packageInfoAsync.when(
                data: (info) => '${info.version} (${info.buildNumber})',
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
          const Divider(height: 1),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
              child: const Text('Log Out'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
