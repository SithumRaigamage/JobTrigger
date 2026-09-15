import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/reduce_transparency_notifier.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../domain/credential/github_credential.dart';
import '../../../domain/credential/jenkins_server.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import '../tool_selection/active_tool_notifier.dart';
import '../tool_selection/ci_tool.dart';
import 'active_github_credential_notifier.dart';
import 'active_server_notifier.dart';
import 'credentials_notifier.dart';
import 'github_credential_edit_bottom_sheet.dart';
import 'github_credentials_notifier.dart';
import 'server_edit_bottom_sheet.dart';

/// Ported from `SettingsView.swift`'s server list — see
/// `docs/state-management.md`'s "Feature: settings / server management".
/// P6-03 added the "Appearance" section back (System/Light/Dark, matching
/// the old app's segmented picker) since a real `ThemeNotifier` now exists
/// to back it. Still skips the old app's "Backend Server Status" section
/// (a live connectivity health-check, not in any phase task list — flagged
/// in `tasks/backlog.md` instead of built here) and its redundant inline
/// (non-sheet) edit form.
///
/// P8-06 (epic GH) restructured the body from a single `Expanded` Jenkins
/// list to a `CustomScrollView` of slivers, so a second, entirely
/// independent "GitHub" section could sit below it in one shared scroll
/// region rather than two competing `Expanded` panes or a second
/// floating-action-button. Each section now has its own inline "add"
/// affordance in its header instead of a single global FAB.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsAsync = ref.watch(credentialsNotifierProvider);
    final activeServer = ref.watch(activeServerNotifierProvider);
    final githubCredentialsAsync = ref.watch(gitHubCredentialsNotifierProvider);
    final activeGithubCredential = ref.watch(
      activeGitHubCredentialNotifierProvider,
    );
    // Settings is reached from the same tab regardless of which CI tool is
    // active, but showing *both* credential sections unconditionally reads
    // as "you're missing GitHub credentials" even to a user who selected
    // Jenkins and has no reason to care about GitHub yet. Scope each
    // section to the tool it's actually for; `null` (pre-selection) falls
    // back to Jenkins, matching this app's other "Jenkins is the default"
    // conventions (e.g. `CiTool.isAvailable`'s ordering).
    final activeTool = ref.watch(activeToolNotifierProvider);
    final showJenkinsSection = activeTool != CiTool.githubActions;
    final showGitHubSection = activeTool == CiTool.githubActions;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Tool Selection',
          onPressed: () => context.go(AppRoutes.toolSelection),
        ),
        title: const Text('Settings'),
      ),
      body: ResponsiveCenter(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
              ),
            ),
            const SliverToBoxAdapter(child: _AppearanceSection()),
            if (showJenkinsSection) ...[
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'JENKINS SERVERS',
                  onAdd: () => showServerEditBottomSheet(context),
                ),
              ),
              ..._credentialSlivers<JenkinsServer>(
                async: credentialsAsync,
                onRetry: () =>
                    ref.read(credentialsNotifierProvider.notifier).refresh(),
                emptyStateBuilder: () => _EmptyState(
                  icon: Icons.dns_outlined,
                  title: 'No Servers Yet',
                  message: 'Add a Jenkins server to get started.',
                  buttonLabel: 'Add Jenkins Server',
                  onAdd: () => showServerEditBottomSheet(context),
                ),
                tileBuilder: (context, server) => _ServerTile(
                  server: server,
                  isActive: server.id == activeServer?.id,
                ),
              ),
            ],
            if (showGitHubSection) ...[
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'GITHUB',
                  onAdd: () => showGitHubCredentialEditBottomSheet(context),
                ),
              ),
              ..._credentialSlivers<GitHubCredential>(
                async: githubCredentialsAsync,
                onRetry: () => ref
                    .read(gitHubCredentialsNotifierProvider.notifier)
                    .refresh(),
                emptyStateBuilder: () => _EmptyState(
                  icon: Icons.hub_outlined,
                  title: 'No GitHub Credentials Yet',
                  message: 'Add a Personal Access Token to get started.',
                  buttonLabel: 'Add GitHub Credential',
                  onAdd: () => showGitHubCredentialEditBottomSheet(context),
                ),
                tileBuilder: (context, credential) => _GitHubCredentialTile(
                  credential: credential,
                  isActive: credential.id == activeGithubCredential?.id,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(height: glassNavBarClearance(context) + 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Shared `AsyncValue<List<T>>.when` → sliver mapping for both sections
  /// — loading/error/empty/populated, same as the original single-section
  /// `_ServerList` handled inline, just returning slivers instead of a
  /// bare widget so both sections can share one `CustomScrollView`.
  /// [tileBuilder] receives each already-typed, definitely-non-null item
  /// from within the `data:` branch — no force-unwrapping an outer
  /// `AsyncValue.value` needed.
  List<Widget> _credentialSlivers<T>({
    required AsyncValue<List<T>> async,
    required VoidCallback onRetry,
    required Widget Function() emptyStateBuilder,
    required Widget Function(BuildContext, T) tileBuilder,
  }) {
    return [
      async.when(
        data: (items) => items.isEmpty
            ? SliverToBoxAdapter(child: emptyStateBuilder())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => tileBuilder(context, items[index]),
                    childCount: items.length,
                  ),
                ),
              ),
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, stackTrace) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add',
            visualDensity: VisualDensity.compact,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onAdd,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
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

class _ServerTile extends ConsumerWidget {
  const _ServerTile({required this.server, required this.isActive});

  final JenkinsServer server;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onTap: isActive ? null : () => _setActiveServer(ref, server),
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
              onPressed: () =>
                  showServerEditBottomSheet(context, existing: server),
            ),
          ),
        ),
      ),
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

/// Mirrors `_ServerTile` exactly, for a `GitHubCredential` instead of a
/// `JenkinsServer` — deliberately not a shared generic widget: the two
/// domain types have different fields (`label`/no-URL-to-show vs.
/// `serverName`/`jenkinsURL`) and different active-credential notifiers,
/// so a generic version would need as many type parameters as it saves
/// lines.
class _GitHubCredentialTile extends ConsumerWidget {
  const _GitHubCredentialTile({
    required this.credential,
    required this.isActive,
  });

  final GitHubCredential credential;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(credential.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => _deleteCredential(ref, credential),
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
        child: GlassSurface.card(
          onTap: isActive ? null : () => _setActiveCredential(ref, credential),
          child: ListTile(
            leading: Icon(
              isActive
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(credential.label),
            subtitle: credential.defaultOwner == null
                ? null
                : Text(credential.defaultOwner!),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () => showGitHubCredentialEditBottomSheet(
                context,
                existing: credential,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete GitHub credential?'),
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

  Future<void> _setActiveCredential(
    WidgetRef ref,
    GitHubCredential credential,
  ) async {
    await ref
        .read(activeGitHubCredentialNotifierProvider.notifier)
        .setActiveCredential(credential);
    ref
        .read(toastControllerProvider)
        .show(
          type: ToastType.success,
          title: 'Credential Switched',
          message: 'Now using ${credential.label}.',
        );
  }

  Future<void> _deleteCredential(
    WidgetRef ref,
    GitHubCredential credential,
  ) async {
    final result = await ref
        .read(activeGitHubCredentialNotifierProvider.notifier)
        .deleteCredential(credential);
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
