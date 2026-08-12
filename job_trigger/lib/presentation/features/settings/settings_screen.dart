import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../domain/credential/jenkins_server.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import '../auth/auth_notifier.dart';
import 'active_server_notifier.dart';
import 'credentials_notifier.dart';
import 'server_edit_bottom_sheet.dart';

/// Ported from `SettingsView.swift`'s server list — see
/// `docs/state-management.md`'s "Feature: settings / server management".
/// P6-03 added the "Appearance" section back (System/Light/Dark, matching
/// the old app's segmented picker) since a real `ThemeNotifier` now exists
/// to back it. Still skips the old app's "Backend Server Status" section
/// (a live connectivity health-check, not in any phase task list — flagged
/// in `tasks/backlog.md` instead of built here) and its redundant inline
/// (non-sheet) edit form.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsAsync = ref.watch(credentialsNotifierProvider);
    final activeServer = ref.watch(activeServerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          const _AppearanceSection(),
          const Divider(height: 1),
          Expanded(
            child: credentialsAsync.when(
              data: (servers) => _ServerList(
                servers: servers,
                activeServerId: activeServer?.id,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: ConnectionErrorView(
                  message: describeError(error),
                  onRetry: () =>
                      ref.read(credentialsNotifierProvider.notifier).refresh(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showServerEditBottomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Jenkins Server'),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPEARANCE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref
                .read(themeNotifierProvider.notifier)
                .setThemeMode(selection.first),
          ),
        ],
      ),
    );
  }
}

class _ServerList extends ConsumerWidget {
  const _ServerList({required this.servers, required this.activeServerId});

  final List<JenkinsServer> servers;
  final String? activeServerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (servers.isEmpty) {
      return const Center(child: Text('No servers added yet.'));
    }
    return ListView.builder(
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers[index];
        final isActive = server.id == activeServerId;
        return Dismissible(
          key: ValueKey(server.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) => _deleteServer(ref, server),
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          child: ListTile(
            title: Text(server.serverName),
            subtitle: Text(server.jenkinsURL),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () =>
                      showServerEditBottomSheet(context, existing: server),
                ),
              ],
            ),
            onTap: isActive
                ? null
                : () => ref
                      .read(activeServerNotifierProvider.notifier)
                      .setActiveServer(server),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete server?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Delete + active-server fallback (P3-09) lives on `ActiveServerNotifier`
  /// so it's unit-testable without a widget tree — this just surfaces the
  /// outcome.
  Future<void> _deleteServer(WidgetRef ref, JenkinsServer server) async {
    final result = await ref
        .read(activeServerNotifierProvider.notifier)
        .deleteServer(server);
    if (result case Err(:final error)) {
      ref
          .read(toastControllerProvider)
          .show(
            type: ToastType.error,
            title: 'Delete Failed',
            message: describeError(error),
          );
    }
  }
}
