import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/reduce_transparency_notifier.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../domain/credential/jenkins_server.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
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
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Tool Selection',
          onPressed: () => context.go(AppRoutes.toolSelection),
        ),
        title: const Text('Settings'),
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            SizedBox(
              height:
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            ),
            const _AppearanceSection(),
            const Divider(height: 1),
            Expanded(
              child: credentialsAsync.when(
                data: (servers) => _ServerList(
                  servers: servers,
                  activeServerId: activeServer?.id,
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: ConnectionErrorView(
                    message: describeError(error),
                    onRetry: () => ref
                        .read(credentialsNotifierProvider.notifier)
                        .refresh(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        // Clears the floating glass bottom nav bar (see MainScaffold's
        // `extendBody: true` and `glassNavBarClearance`) — without this the
        // FAB would sit partly behind it.
        padding: EdgeInsets.only(bottom: glassNavBarClearance(context)),
        child: FloatingActionButton.extended(
          onPressed: () => showServerEditBottomSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Jenkins Server'),
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final reduceTransparency = ref.watch(reduceTransparencyNotifierProvider);

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
          // US-DESIGN-03: manual accessibility fallback for the glass
          // effect -- Flutter doesn't expose iOS's "Reduce Transparency"
          // signal, so this is a first-party toggle rather than an
          // OS auto-detect. See ReduceTransparencyNotifier.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduce transparency'),
            subtitle: const Text(
              'Use solid surfaces instead of frosted glass',
            ),
            value: reduceTransparency,
            onChanged: (value) => ref
                .read(reduceTransparencyNotifierProvider.notifier)
                .setReduceTransparency(value),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dns_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 20),
              Text(
                'No Servers Yet',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a Jenkins server to get started.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => showServerEditBottomSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Jenkins Server'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        12 + glassNavBarClearance(context),
      ),
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers[index];
        final isActive = server.id == activeServerId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey(server.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(context),
            onDismissed: (_) => _deleteServer(ref, server),
            background: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            // `onTap` lives on GlassSurface.card itself, not the ListTile
            // -- a ListTile's ink splashes paint on the nearest ancestor
            // Material, and GlassSurface's DecoratedBox fill would sit
            // between the ListTile and that ancestor and hide them
            // (Flutter's own "ListTile background color or ink splashes
            // may be invisible" warning) unless routed through here.
            child: GlassSurface.card(
              onTap: isActive
                  ? null
                  : () => _setActiveServer(ref, server),
              child: ListTile(
                // A radio-style selection indicator, not just a checkmark
                // that only ever appears on the active row -- without a
                // control on every row, nothing suggested the *other* rows
                // were tappable to select them (the whole-row tap "worked"
                // but had no discoverable affordance).
                leading: Icon(
                  isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(server.serverName),
                subtitle: Text(server.jenkinsURL),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => showServerEditBottomSheet(
                    context,
                    existing: server,
                  ),
                ),
              ),
            ),
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

  /// Confirms the switch actually happened — without this, nothing told
  /// the user their tap took effect beyond the radio icon silently moving.
  Future<void> _setActiveServer(WidgetRef ref, JenkinsServer server) async {
    await ref.read(activeServerNotifierProvider.notifier).setActiveServer(
      server,
    );
    ref
        .read(toastControllerProvider)
        .show(
          type: ToastType.success,
          title: 'Server Switched',
          message: 'Now using ${server.serverName}.',
        );
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
