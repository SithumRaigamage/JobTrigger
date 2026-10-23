import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/credential/server_url.dart';
import '../../common_widgets/grouped_card.dart';
import '../../../core/theme/reduce_transparency_notifier.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../domain/credential/github_credential.dart';
import '../../../domain/credential/jenkins_server.dart';
import '../../../domain/credential/token_hygiene.dart';
import '../home/server_status_provider.dart';
import '../../../domain/jenkins/server_status.dart';
import '../../../core/config/app_config.dart';
import '../../../domain/credential/sonarqube_credential.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/secret_reentry_notice.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/main_scaffold.dart';
import '../tool_selection/active_tool_notifier.dart';
import '../tool_selection/ci_tool.dart';
import '../../../data/credentials/active_github_credential_notifier.dart';
import '../notifications/build_watch_notifier.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/credentials/credentials_notifier.dart';
import 'github_credential_edit_bottom_sheet.dart';
import '../../../data/credentials/github_credentials_notifier.dart';
import 'server_edit_bottom_sheet.dart';
import 'sonarqube_credential_edit_bottom_sheet.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';

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
    final sonarQubeCredentialsAsync = ref.watch(
      sonarQubeCredentialsNotifierProvider,
    );
    final activeSonarQubeCredential = ref.watch(
      activeSonarQubeCredentialNotifierProvider,
    );
    // Settings is reached from the same tab regardless of which CI tool is
    // active, but showing *every* credential section unconditionally reads
    // as "you're missing GitHub/SonarQube credentials" even to a user who
    // selected Jenkins and has no reason to care about either yet. Scope
    // each section to the tool it's actually for; `null` (pre-selection)
    // falls back to Jenkins, matching this app's other "Jenkins is the
    // default" conventions (e.g. `CiTool.isAvailable`'s ordering).
    final activeTool = ref.watch(activeToolNotifierProvider);
    final showJenkinsSection =
        activeTool != CiTool.githubActions && activeTool != CiTool.sonarqube;
    final showGitHubSection = activeTool == CiTool.githubActions;
    final showSonarQubeSection = activeTool == CiTool.sonarqube;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
              ),
              if (showJenkinsSection)
                ..._section<JenkinsServer>(
                  title: 'Jenkins servers',
                  addLabel: 'Add Jenkins server',
                  onAdd: () => showServerEditBottomSheet(context),
                  async: credentialsAsync,
                  onRetry: () =>
                      ref.read(credentialsNotifierProvider.notifier).refresh(),
                  emptyStateBuilder: () => _EmptyState(
                    icon: Icons.dns_outlined,
                    title: 'No servers yet',
                    message: 'Add a Jenkins server to get started.',
                    buttonLabel: 'Add Jenkins server',
                    onAdd: () => showServerEditBottomSheet(context),
                  ),
                  tileBuilder: (context, server) => _ServerTile(
                    server: server,
                    isActive: server.id == activeServer?.id,
                  ),
                ),
              if (showGitHubSection)
                ..._section<GitHubCredential>(
                  title: 'GitHub',
                  addLabel: 'Add GitHub credential',
                  onAdd: () => showGitHubCredentialEditBottomSheet(context),
                  async: githubCredentialsAsync,
                  onRetry: () => ref
                      .read(gitHubCredentialsNotifierProvider.notifier)
                      .refresh(),
                  emptyStateBuilder: () => _EmptyState(
                    icon: Icons.hub_outlined,
                    title: 'No GitHub credentials yet',
                    message: 'Add a Personal Access Token to get started.',
                    buttonLabel: 'Add GitHub credential',
                    onAdd: () => showGitHubCredentialEditBottomSheet(context),
                  ),
                  tileBuilder: (context, credential) => _GitHubCredentialTile(
                    credential: credential,
                    isActive: credential.id == activeGithubCredential?.id,
                  ),
                ),
              if (showSonarQubeSection)
                ..._section<SonarQubeCredential>(
                  title: 'SonarQube',
                  addLabel: 'Add SonarQube credential',
                  onAdd: () => showSonarQubeCredentialEditBottomSheet(context),
                  async: sonarQubeCredentialsAsync,
                  onRetry: () => ref
                      .read(sonarQubeCredentialsNotifierProvider.notifier)
                      .refresh(),
                  emptyStateBuilder: () => _EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'No SonarQube credentials yet',
                    message: 'Add a User Token to get started.',
                    buttonLabel: 'Add SonarQube credential',
                    onAdd: () =>
                        showSonarQubeCredentialEditBottomSheet(context),
                  ),
                  tileBuilder: (context, credential) =>
                      _SonarQubeCredentialTile(
                        credential: credential,
                        isActive:
                            credential.id == activeSonarQubeCredential?.id,
                      ),
                ),
              const _Padded(child: _AppearanceSection()),
              // US-JX-10.
              const _Padded(child: _WatchesSection()),
              SliverToBoxAdapter(
                child: SizedBox(height: glassNavBarClearance(context) + 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One credential section: its heading with an inline Add, then the
  /// saved items as one grouped card — or loading, an error with retry, or
  /// the empty state. [tileBuilder] receives each already-typed item.
  List<Widget> _section<T>({
    required String title,
    required String addLabel,
    required VoidCallback onAdd,
    required AsyncValue<List<T>> async,
    required VoidCallback onRetry,
    required Widget Function() emptyStateBuilder,
    required Widget Function(BuildContext, T) tileBuilder,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
        sliver: SliverToBoxAdapter(
          child: GroupHeader(
            title: title,
            action: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add', semanticsLabel: addLabel),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: async.when(
            data: (items) => items.isEmpty
                ? emptyStateBuilder()
                : Builder(
                    builder: (context) => GroupedCard(
                      children: [
                        for (final item in items) tileBuilder(context, item),
                      ],
                    ),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => ConnectionErrorView(
              message: describeError(error),
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    ];
  }
}

/// A non-credential section, padded like the rest.
class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    sliver: SliverToBoxAdapter(child: child),
  );
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
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GroupedCard(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          children: [
            Icon(icon, size: 40, color: t.textMuted),
            const SizedBox(height: 12),
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final reduceTransparency = ref.watch(reduceTransparencyNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupHeader(title: 'Appearance'),
        GroupedCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) => ref
                    .read(themeNotifierProvider.notifier)
                    .setThemeMode(selection.first),
              ),
            ),
            // US-DESIGN-03: a first-party toggle -- Flutter doesn't expose
            // iOS's "Reduce Transparency" signal. See
            // ReduceTransparencyNotifier.
            SwitchListTile(
              title: const Text('Reduce transparency'),
              subtitle: const Text('Solid bars instead of see-through ones'),
              value: reduceTransparency,
              onChanged: (value) => ref
                  .read(reduceTransparencyNotifierProvider.notifier)
                  .setReduceTransparency(value),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServerTile extends ConsumerWidget {
  const _ServerTile({required this.server, required this.isActive});

  final JenkinsServer server;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(server.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _deleteServer(ref, server),
      background: Container(
        color: AppTokens.of(context).failure.background,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTokens.of(context).failure.foreground,
        ),
      ),
      child: _CredentialRow(
        isActive: isActive,
        title: server.serverName,
        onActivate: () => _setActiveServer(ref, server),
        onEdit: () async {
          // P14-22: the sheet's own "Delete server" ends the same way a
          // swipe does — confirmed, then deleted.
          final delete = await showServerEditBottomSheet(
            context,
            existing: server,
          );
          if (delete == true &&
              context.mounted &&
              await _confirmDelete(context)) {
            await _deleteServer(ref, server);
          }
        },
        details: [
          _MonoLine(server.jenkinsURL),
          // AUD-14 / AUD-52: the design flags a server reached over
          // plain http.
          if (isCleartextUrl(server.jenkinsURL)) const _CleartextLine(),
          if (isActive)
            _ActiveServerSubtitle(server: server)
          else if (server.needsReentry)
            const SecretReentryNotice()
          else if (!looksLikeJenkinsApiToken(server.secret))
            const _NoteLine('Uses a password'),
        ],
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
    await ref
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(server);
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
    return Dismissible(
      key: ValueKey(credential.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _deleteCredential(ref, credential),
      background: Container(
        color: AppTokens.of(context).failure.background,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTokens.of(context).failure.foreground,
        ),
      ),
      child: _CredentialRow(
        isActive: isActive,
        title: credential.label,
        onActivate: () => _setActiveCredential(ref, credential),
        onEdit: () async {
          final delete = await showGitHubCredentialEditBottomSheet(
            context,
            existing: credential,
          );
          if (delete == true &&
              context.mounted &&
              await _confirmDelete(context)) {
            await _deleteCredential(ref, credential);
          }
        },
        // AUD-63: an unreadable secret takes precedence over the owner
        // hint — the credential can't authenticate at all.
        details: [
          if (credential.needsReentry)
            const SecretReentryNotice()
          else if (credential.defaultOwner != null)
            _MonoLine(credential.defaultOwner!),
        ],
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

/// Mirrors `_GitHubCredentialTile` exactly, for a `SonarQubeCredential`
/// instead — deliberately not a shared generic widget, same reasoning as
/// `_GitHubCredentialTile`'s own doc comment.
class _SonarQubeCredentialTile extends ConsumerWidget {
  const _SonarQubeCredentialTile({
    required this.credential,
    required this.isActive,
  });

  final SonarQubeCredential credential;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(credential.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _deleteCredential(ref, credential),
      background: Container(
        color: AppTokens.of(context).failure.background,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTokens.of(context).failure.foreground,
        ),
      ),
      child: _CredentialRow(
        isActive: isActive,
        title: credential.label,
        onActivate: () => _setActiveCredential(ref, credential),
        onEdit: () async {
          final delete = await showSonarQubeCredentialEditBottomSheet(
            context,
            existing: credential,
          );
          if (delete == true &&
              context.mounted &&
              await _confirmDelete(context)) {
            await _deleteCredential(ref, credential);
          }
        },
        // AUD-63: an unreadable secret takes precedence over the URL.
        details: [
          if (credential.needsReentry)
            const SecretReentryNotice()
          else ...[
            _MonoLine(credential.baseUrl),
            if (isCleartextUrl(credential.baseUrl)) const _CleartextLine(),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SonarQube credential?'),
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
    SonarQubeCredential credential,
  ) async {
    await ref
        .read(activeSonarQubeCredentialNotifierProvider.notifier)
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
    SonarQubeCredential credential,
  ) async {
    final result = await ref
        .read(activeSonarQubeCredentialNotifierProvider.notifier)
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

/// US-JX-18 + US-JX-22 for the active server: its URL, Jenkins version
/// (with an upgrade hint when old), and the password advisory.
class _ActiveServerSubtitle extends ConsumerWidget {
  const _ActiveServerSubtitle({required this.server});

  final JenkinsServer server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(
      serverStatusProvider.select((status) => status.value?.version),
    );
    final notes = [
      if (version != null)
        isOutdatedJenkins(version, AppConfig.recommendedJenkinsBaseline)
            ? 'Jenkins $version · consider upgrading'
            : 'Jenkins $version',
      // AUD-63: a null secret means the backend couldn't decrypt it, not
      // that the credential uses a password — "Uses a password" would
      // send the user looking for a password that isn't there.
      if (!server.needsReentry && !looksLikeJenkinsApiToken(server.secret))
        'Uses a password',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notes.isNotEmpty) _NoteLine(notes.join(' · ')),
        if (server.needsReentry)
          const SecretReentryNotice(
            detail:
                'The secret could not be read from the server — edit this '
                'server to enter it again.',
          ),
      ],
    );
  }
}

/// US-JX-10: what the user will be notified about, with a way to stop.
class _WatchesSection extends ConsumerWidget {
  const _WatchesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watches = ref.watch(buildWatchNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupHeader(title: 'Notifications'),
        if (watches.isEmpty)
          Text(
            'Tap the bell on a job to be notified when builds finish.',
            style: textTheme.bodySmall,
          )
        else
          GroupedCard(
            children: [
              for (final watch in watches)
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(watch.jobLabel),
                  subtitle: Text(
                    watch.isJobWatch
                        ? 'Every build'
                        : 'Build #${watch.buildNumber}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Stop notifying',
                    onPressed: () => ref
                        .read(buildWatchNotifierProvider.notifier)
                        .unwatch(watch),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          'While the app is closed, checks run when your phone allows — '
          'usually every 15 minutes or more.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// One saved server or credential in its group: a radio mark and tap to
/// make it the active one, its details, and an edit button. Shared by the
/// three credential kinds so they can't drift apart.
class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.isActive,
    required this.title,
    required this.onActivate,
    required this.onEdit,
    this.details = const [],
  });

  final bool isActive;
  final String title;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            selected: isActive,
            inMutuallyExclusiveGroup: true,
            child: InkWell(
              // A radio mark on every row, so the inactive ones read as
              // choosable, not just the active one with a tick.
              onTap: isActive ? null : onActivate,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: _RadioMark(selected: isActive),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ...details,
                        ],
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          'Active',
                          style: textTheme.labelSmall?.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: 'Edit $title',
          onPressed: onEdit,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colorScheme.primary : Colors.transparent,
          border: selected
              ? null
              : Border.all(color: colorScheme.outline, width: 2),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 14, color: colorScheme.onPrimary)
            : null,
      ),
    );
  }
}

/// A URL or name as Jenkins and GitHub write it.
class _MonoLine extends StatelessWidget {
  const _MonoLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTypography.mono(
      Theme.of(context).textTheme.bodySmall,
    ).copyWith(fontSize: 12),
  );
}

/// A secondary note under a row: Jenkins version, "Uses a password".
class _NoteLine extends StatelessWidget {
  const _NoteLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
    ),
  );
}

/// AUD-14 / AUD-52: this server is reached over plain `http://`.
class _CleartextLine extends StatelessWidget {
  const _CleartextLine();

  @override
  Widget build(BuildContext context) {
    final color = AppTokens.of(context).unstable.foreground;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.lock_open_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'http:// — not encrypted',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
