import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/credentials_notifier.dart';
import '../../../domain/credential/jenkins_server.dart';
import '../../../domain/credential/server_links.dart';
import '../../../domain/jenkins/branch_kind.dart';
import '../../../domain/jenkins/build_progress.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/jenkins_view.dart';
import '../../../domain/jenkins/job_status_summary.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/no_active_server_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/secret_reentry_notice.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_indicator.dart';
import '../../common_widgets/status_pill.dart';
import '../../common_widgets/status_tile.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'folder_breadcrumb_notifier.dart';
import 'folder_contents_notifier.dart';
import 'home_server_gate_provider.dart';
import 'job_search_notifier.dart';
import 'multibranch_notifiers.dart';
import 'pinned_jobs_notifier.dart';
import 'server_status_provider.dart';
import 'views_notifier.dart';
import 'visible_jobs_provider.dart';

/// Ported from `HomeView.swift`, laid out to the P14 design
/// (`UI-UX/screens/05-home-jenkins-dark`, `06-home-jenkins-light`): the
/// active server and the queue/nodes shortcuts on top, the view (or
/// folder) as the title, search, a Running / Failing / Passing strip at
/// the root, pinned jobs as cards, then every job in one grouped list.
///
/// P6-06 (Android review): folder navigation is in-place breadcrumb state
/// on this single screen, not a `go_router` push per folder — same
/// approach the old app used (`HomeViewModel.navigateInto` on one
/// `NavigationStack` entry, no per-folder push), so there's no regression
/// there. But Android's system back gesture/button is a harder OS-level
/// expectation than iOS's edge-swipe-to-pop, and without help it would pop
/// this whole route (exiting Home) instead of going up one folder level —
/// standard Android UX (e.g. file browsers) expects back to walk up first.
/// `PopScope` intercepts it: blocks the pop and calls `navigateBack()`
/// while inside a folder, only lets the route actually pop at the root.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerNotifierProvider);
    if (activeServer == null) {
      // P19-02: "no server yet" is not "no server saved".
      final body = switch (ref.watch(homeServerGateProvider)) {
        HomeServerNone() => const NoActiveServerView(),
        HomeServerFailed(:final error) => ConnectionErrorView(
          message: describeError(error),
          onRetry: () {
            ref.invalidate(credentialsNotifierProvider);
            ref.invalidate(activeServerNotifierProvider);
          },
        ),
        HomeServerLoading() => const CircularProgressIndicator(),
      };
      return Scaffold(
        body: SafeArea(child: Center(child: body)),
      );
    }

    final visibleJobs = ref.watch(visibleJobsProvider);
    final breadcrumb = ref.watch(folderBreadcrumbNotifierProvider);
    final query = ref.watch(jobSearchNotifierProvider);

    return PopScope(
      canPop: breadcrumb.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(folderBreadcrumbNotifierProvider.notifier).navigateBack();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(server: activeServer, breadcrumb: breadcrumb),
                Expanded(
                  child: visibleJobs.when(
                    data: (jobs) => _JobList(
                      jobs: jobs,
                      atRoot: breadcrumb.isEmpty,
                      searching: query.isNotEmpty,
                      // Branch/PR/tag sections only when browsing (not
                      // searching) inside a multibranch project.
                      multibranch:
                          breadcrumb.isNotEmpty &&
                              breadcrumb.last.isMultibranch &&
                              query.isEmpty
                          ? breadcrumb.last
                          : null,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: ConnectionErrorView(
                        message: describeError(error),
                        onRetry: () => refreshVisibleJobs(ref),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything above the list: the server (or the way back out of a
/// folder) and shortcuts, the title, search, and any server-wide notice.
class _Header extends ConsumerWidget {
  const _Header({required this.server, required this.breadcrumb});

  final JenkinsServer server;
  final List<FolderRef> breadcrumb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final folder = breadcrumb.isEmpty ? null : breadcrumb.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (folder == null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ServerChip(server: server),
                  ),
                )
              else
                Transform.translate(
                  offset: const Offset(-10, 0),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => ref
                        .read(folderBreadcrumbNotifierProvider.notifier)
                        .navigateBack(),
                  ),
                ),
              if (folder != null) const Spacer(),
              if (folder != null && folder.isScannable)
                _ScanActions(project: folder),
              if (folder == null) ...[
                _HeaderButton(
                  icon: Icons.format_list_bulleted_rounded,
                  tooltip: 'Build queue',
                  onPressed: () => context.push(AppRoutes.queue),
                ),
                const SizedBox(width: 8),
                _HeaderButton(
                  icon: Icons.dns_outlined,
                  tooltip: 'Nodes',
                  onPressed: () => context.push(AppRoutes.nodes),
                ),
                const SizedBox(width: 8),
              ],
              _MoreMenu(
                withShortcuts: folder != null,
                webUrl: jenkinsWebUrl(folder?.url ?? server.jenkinsURL),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (folder == null)
            const _ViewPickerTitle()
          else ...[
            Text(folder.label, style: textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              ['Home', ...breadcrumb.map((f) => f.label)].join(' / '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 14),
          const _SearchField(),
          if (ref.watch(jobSearchNotifierProvider).isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.travel_explore_rounded,
                  size: 16,
                  color: t.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Searching across all folders',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
          const _OfflineBanner(),
          const _QuietDownBanner(),
        ],
      ),
    );
  }
}

/// The active server, with a dot for whether it's reachable. Tapping it
/// drops down the saved servers to switch between (P19-07); "Manage
/// servers…" leads on to Settings, where they're added, edited and removed.
class _ServerChip extends ConsumerWidget {
  const _ServerChip({required this.server});

  final JenkinsServer server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final offline = ref.watch(offlineSnapshotNotifierProvider) != null;
    // Until the saved list loads, the active server is the only choice.
    final saved = ref.watch(credentialsNotifierProvider).value;
    final servers = saved == null || !saved.any((s) => s.id == server.id)
        ? [server, ...?saved]
        : saved;
    return Semantics(
      button: true,
      label:
          'Server ${server.serverName}${offline ? ', offline' : ''}. '
          'Switch server',
      excludeSemantics: true,
      child: Material(
        color: t.card,
        shape: StadiumBorder(side: BorderSide(color: t.cardBorder)),
        child: PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          borderRadius: BorderRadius.circular(22),
          onSelected: (id) {
            if (id == _manageServersAction) {
              context.go(AppRoutes.settings);
              return;
            }
            final chosen = servers.firstWhere((s) => s.id == id);
            if (chosen.id == server.id) return;
            unawaited(
              ref
                  .read(activeServerNotifierProvider.notifier)
                  .setActiveServer(chosen),
            );
          },
          itemBuilder: (context) => [
            for (final option in servers)
              PopupMenuItem(
                value: option.id,
                child: _ServerOption(
                  server: option,
                  isActive: option.id == server.id,
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _manageServersAction,
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Manage servers…'),
              ),
            ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: offline ? t.neutral.dot : t.success.dot,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      server.serverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: t.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _manageServersAction = 'manage-servers';

/// One saved server in the chip's menu: a check on the active one, its
/// name, its address, and a note when its secret has to be entered again.
class _ServerOption extends StatelessWidget {
  const _ServerOption({required this.server, required this.isActive});

  final JenkinsServer server;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: isActive,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: isActive
                ? Icon(Icons.check_rounded, size: 20, color: t.success.dot)
                : null,
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  server.serverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                Text(
                  server.jenkinsURL,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                ),
                if (server.needsReentry) const SecretReentryNotice(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A square shortcut button in the header (`UI-UX/screens/05`).
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: t.card,
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.cardBorder),
        ),
      ),
    );
  }
}

/// US-JX-19 (open a pasted Jenkins link) — plus, inside a folder where the
/// header has room only for the scan actions, the queue and nodes
/// (US-JX-09 / US-JX-12).
/// The overflow menu. "Open Jenkins link" opens [webUrl] — the server, or
/// the folder being browsed — in the browser (P19-06); shortcuts to the
/// queue and nodes join it inside a folder, where the header buttons don't.
class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.withShortcuts, required this.webUrl});

  final bool withShortcuts;
  final Uri? webUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        if (value != _openLinkAction) {
          unawaited(context.push(value));
        } else if (webUrl case final uri?) {
          unawaited(openExternalLink(ref, uri));
        } else {
          ref
              .read(toastControllerProvider)
              .show(
                type: ToastType.error,
                title: "Couldn't open link",
                message: 'This server’s address isn’t a valid web link.',
              );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _openLinkAction,
          child: ListTile(
            leading: Icon(Icons.open_in_browser_rounded),
            title: Text('Open Jenkins link'),
          ),
        ),
        if (withShortcuts) ...const [
          PopupMenuItem(
            value: AppRoutes.queue,
            child: ListTile(
              leading: Icon(Icons.format_list_bulleted_rounded),
              title: Text('Build queue'),
            ),
          ),
          PopupMenuItem(
            value: AppRoutes.nodes,
            child: ListTile(
              leading: Icon(Icons.dns_outlined),
              title: Text('Nodes'),
            ),
          ),
        ],
      ],
    );
  }
}

const _openLinkAction = 'open-link';

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Search jobs',
      child: TextField(
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search jobs',
          prefixIcon: Icon(Icons.search_rounded, size: 20),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (query) =>
            ref.read(jobSearchNotifierProvider.notifier).setQuery(query),
      ),
    );
  }
}

class _JobList extends ConsumerWidget {
  const _JobList({
    required this.jobs,
    required this.atRoot,
    required this.searching,
    this.multibranch,
  });

  final List<JenkinsJob> jobs;
  final bool atRoot;
  final bool searching;

  /// The multibranch project being browsed, if any: its jobs are grouped
  /// into branch / pull request / tag sections (US-JX-03).
  final FolderRef? multibranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pins sit above the root list only (US-JX-11).
    final pins = atRoot && !searching
        ? ref.watch(pinnedJobsNotifierProvider)
        : const <PinnedJob>[];
    if (jobs.isEmpty && pins.isEmpty) {
      // Still pull-to-refreshable: an empty folder may just be stale
      // (AUD-33).
      return RefreshIndicator(
        onRefresh: () => refreshVisibleJobs(ref),
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: _EmptyState(query: ref.watch(jobSearchNotifierProvider)),
              ),
            ],
          ),
        ),
      );
    }

    final project = multibranch;
    // Grouping is additive: until (or if) the views load, show one list.
    final kinds = project == null
        ? null
        : ref.watch(branchKindsProvider(project.url)).value;
    final sections = kinds == null
        ? [(searching ? 'Results' : 'All jobs', jobs)]
        : _grouped(jobs, kinds);
    final summary = JobStatusSummary.of(jobs);

    return RefreshIndicator(
      onRefresh: () => refreshVisibleJobs(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (atRoot && !searching && !summary.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              sliver: SliverToBoxAdapter(child: _SummaryStrip(summary)),
            ),
          if (pins.isNotEmpty) ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              sliver: SliverToBoxAdapter(
                child: SectionLabel('Pinned', icon: Icons.push_pin_outlined),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverList.separated(
                itemCount: pins.length,
                itemBuilder: (context, i) => _PinnedCard(pin: pins[i]),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
              ),
            ),
          ],
          for (final (title, section) in sections)
            if (section.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: SectionLabel(title, trailing: '${section.length}'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: _JobGroup(
                  jobs: section,
                  // Search spans every folder, so say where each result
                  // lives (AUD-33).
                  showFolderPath: searching,
                ),
              ),
            ],
          SliverToBoxAdapter(
            child: SizedBox(height: 16 + glassNavBarClearance(context)),
          ),
        ],
      ),
    );
  }

  /// Each section's title with its jobs, in branches → pull requests →
  /// tags order, empty sections omitted.
  static List<(String, List<JenkinsJob>)> _grouped(
    List<JenkinsJob> jobs,
    Map<String, BranchKind> kinds,
  ) => [
    for (final kind in BranchKind.values)
      (
        kind.sectionTitle,
        jobs
            .where((job) => (kinds[job.name] ?? BranchKind.branch) == kind)
            .toList(),
      ),
  ];
}

/// Running / Failing / Passing at the current level.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip(this.summary);

  final JobStatusSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    Widget tile(int count, String label, StatusColors colors) => Expanded(
      child: MergeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style:
                    AppTypography.mono(
                      Theme.of(context).textTheme.titleLarge,
                    ).copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: colors.foreground),
              ),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        tile(summary.running, 'Running', t.running),
        const SizedBox(width: 8),
        tile(summary.failing, 'Failing', t.failure),
        const SizedBox(width: 8),
        tile(summary.passing, 'Passing', t.success),
      ],
    );
  }
}

/// A run of jobs drawn as one card with hairlines between them, built
/// lazily so a folder with hundreds of jobs stays cheap.
class _JobGroup extends StatelessWidget {
  const _JobGroup({required this.jobs, required this.showFolderPath});

  final List<JenkinsJob> jobs;
  final bool showFolderPath;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      sliver: SliverList.separated(
        itemCount: jobs.length,
        itemBuilder: (context, i) => _JobRow(
          job: jobs[i],
          showFolderPath: showFolderPath,
          first: i == 0,
          last: i == jobs.length - 1,
        ),
        separatorBuilder: (_, _) => const Divider(),
      ),
    );
  }
}

/// The status word shown beside a job, from its ball colour: "Running"
/// while it builds, otherwise the last result.
(String, StatusTone) _statusOf(String? color) =>
    AppColors.isJobColorAnimating(color)
    ? ('Running', StatusTone.running)
    : (AppColors.describeJobColor(color), AppColors.toneForJobColor(color));

/// "#311 · 2h ago", "No builds", or "Disabled".
String _buildLine(JenkinsJob job) {
  final last = job.lastBuild;
  final parts = [
    if (last == null) 'No builds' else '#${last.number}',
    if (last != null && last.timestamp > 0)
      relativeTime(fromJenkinsTimestamp(last.timestamp)),
  ];
  return parts.join(' · ');
}

class _JobRow extends ConsumerWidget {
  const _JobRow({
    required this.job,
    required this.showFolderPath,
    required this.first,
    required this.last,
  });

  final JenkinsJob job;
  final bool showFolderPath;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final pinned = ref.watch(
      pinnedJobsNotifierProvider.select(
        (pins) => pins.any((pin) => pin.url == job.url),
      ),
    );
    final folderPath = showFolderPath ? folderPathOf(job.url) : '';
    final description = job.description;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(first ? 16 : 0),
          bottom: Radius.circular(last ? 16 : 0),
        ),
        onTap: () {
          if (job.isFolder) {
            ref
                .read(folderBreadcrumbNotifierProvider.notifier)
                .navigateInto(job);
          } else {
            context.push(AppRoutes.jobDetail, extra: job);
          }
        },
        // Long-press pins or unpins a job (US-JX-11); folders aren't
        // pinnable.
        onLongPress: job.isFolder ? null : () => _togglePin(context, ref, job),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: job.isFolder
                      ? Icon(
                          // Distinct shapes, not just colour (NFR-A11Y-03):
                          // a multibranch project and an organization
                          // folder aren't plain folders (US-JX-03).
                          job.isMultibranch
                              ? Icons.account_tree_outlined
                              : job.isScannable
                              ? Icons.corporate_fare_rounded
                              : Icons.folder_outlined,
                          size: 20,
                          color: t.unstable.foreground,
                        )
                      : Center(child: StatusIndicator(color: job.color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.label,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (folderPath.isNotEmpty)
                        Text(
                          folderPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                      const SizedBox(height: 2),
                      if (job.isFolder)
                        Text(
                          job.isMultibranch
                              ? 'Multibranch project'
                              : job.isScannable
                              ? 'Organization folder'
                              : 'Folder',
                          style: textTheme.bodySmall?.copyWith(fontSize: 12),
                        )
                      else
                        Row(
                          children: [
                            if (job.buildable == false) ...[
                              // US-JX-13: icon + text, never colour alone.
                              Icon(Icons.block, size: 12, color: t.textMuted),
                              Text(
                                ' Disabled · ',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                _buildLine(job),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.mono(
                                  textTheme.bodySmall,
                                ).copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      if (description != null && description.isNotEmpty)
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (pinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: t.textMuted,
                      semanticLabel: 'Pinned',
                    ),
                  ),
                if (job.isFolder)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: t.textMuted,
                  )
                else
                  // The dot's own label already says this to a screen
                  // reader.
                  ExcludeSemantics(child: _StatusWord(color: job.color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusWord extends StatelessWidget {
  const _StatusWord({required this.color});

  final String? color;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = _statusOf(color);
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTokens.of(context).status(tone).foreground,
      ),
    );
  }
}

Future<void> _togglePin(
  BuildContext context,
  WidgetRef ref,
  JenkinsJob job,
) async {
  final nowPinned = await ref
      .read(pinnedJobsNotifierProvider.notifier)
      .toggle(job);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        nowPinned ? 'Pinned ${job.label}' : 'Unpinned ${job.label}',
      ),
    ),
  );
}

/// A pinned job with its live status (US-JX-11): a status tile, the last
/// build, a progress bar while it builds, and its status as a pill. A pin
/// whose job no longer exists says so, with a button to remove it.
class _PinnedCard extends ConsumerWidget {
  const _PinnedCard({required this.pin});

  final PinnedJob pin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pinnedJobStatusProvider(pin.url));
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final job = status.value;
    final missing = status.hasValue && job == null;
    final loading = status.isLoading && !status.hasValue;
    final (label, tone) = missing || job == null
        ? ('Not found', StatusTone.neutral)
        : _statusOf(job.color);
    final colors = t.status(tone);
    final building = job?.lastBuild?.building ?? false;

    void unpin() =>
        ref.read(pinnedJobsNotifierProvider.notifier).unpin(pin.url);

    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: 'Unpin ${pin.label}'): unpin,
      },
      child: GlassSurface.card(
        padding: const EdgeInsets.all(14),
        onTap: job == null
            ? null
            : () => context.push(AppRoutes.jobDetail, extra: job),
        child: Row(
          children: [
            if (loading)
              SizedBox(
                width: 36,
                height: 36,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.foreground,
                  ),
                ),
              )
            else
              StatusTile(
                tone: tone,
                size: 36,
                icon: missing ? Icons.link_off_rounded : null,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pin.label, style: textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    missing
                        ? 'Not found — it may have been deleted or renamed'
                        : status.hasError
                        ? describeError(status.error!)
                        : job == null
                        ? 'Checking status…'
                        : _buildLine(job),
                    style: missing || status.hasError || job == null
                        ? textTheme.bodySmall?.copyWith(fontSize: 12)
                        : AppTypography.mono(
                            textTheme.bodySmall,
                          ).copyWith(fontSize: 12),
                  ),
                  if (building && job?.lastBuild != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: BuildProgress.ratioFor(job!.lastBuild!),
                        semanticsLabel: 'Build progress',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (missing)
              IconButton(
                icon: const Icon(Icons.push_pin),
                tooltip: 'Unpin ${pin.label}',
                onPressed: unpin,
              )
            else if (job != null)
              StatusPill(label: label, tone: tone),
          ],
        ),
      ),
    );
  }
}

/// US-JX-03: "Scan now" plus the scan log, for a multibranch project or
/// organization folder. Scanning is a state-changing POST, so it asks first.
class _ScanActions extends ConsumerWidget {
  const _ScanActions({required this.project});

  final FolderRef project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanning = ref.watch(multibranchScanNotifierProvider(project.url));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (scanning)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Scan now',
            onPressed: () => _confirmAndScan(context, ref),
          ),
        IconButton(
          icon: const Icon(Icons.receipt_long),
          tooltip: 'Scan log',
          onPressed: () => context.push(
            AppRoutes.buildLog,
            extra: JenkinsBuild(
              number: 0,
              url:
                  '${project.url.endsWith('/') ? project.url : '${project.url}/'}indexing/',
              timestamp: 0,
              displayName: 'Scan log · ${project.label}',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndScan(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Scan ${project.label}?',
      message:
          'Jenkins will re-scan the repository for branches, pull requests, '
          'and tags, and may start builds for new ones.',
      confirmLabel: 'Scan',
    );
    if (!confirmed) return;
    await ref
        .read(multibranchScanNotifierProvider(project.url).notifier)
        .scan();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: t.textMuted),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? 'No jobs found' : 'No results for "$query"',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

/// US-JX-18: Jenkins is preparing for shutdown. Triggers still succeed, but
/// the builds just wait, so say so before someone wonders why.
class _QuietDownBanner extends ConsumerWidget {
  const _QuietDownBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quieting = ref.watch(
      serverStatusProvider.select((status) => status.value?.quietingDown),
    );
    if (quieting != true) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: InlineAlert(
        icon: Icons.power_settings_new_rounded,
        tone: StatusTone.unstable,
        message:
            'Jenkins is preparing for shutdown — new builds are queued '
            "but won't start.",
      ),
    );
  }
}

/// US-JX-17: at Home's root the title is the current view, tappable to
/// switch when the server has more than one.
class _ViewPickerTitle extends ConsumerWidget {
  const _ViewPickerTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(jenkinsViewsProvider).value ?? const [];
    final selectedUrl = ref.watch(selectedViewNotifierProvider);
    final current = views
        .where(
          (view) =>
              selectedUrl == null ? view.isPrimary : view.url == selectedUrl,
        )
        .firstOrNull;
    final title = current?.label ?? 'Jobs';
    final style = Theme.of(context).textTheme.headlineLarge;
    if (views.length < 2) {
      return Semantics(header: true, child: Text(title, style: style));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _pick(context, ref, views, current),
        child: Semantics(
          header: true,
          hint: 'Switch view',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 30,
                color: AppTokens.of(context).textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    List<JenkinsView> views,
    JenkinsView? current,
  ) async {
    final chosen = await showModalBottomSheet<JenkinsView>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final view in views)
              ListTile(
                leading: Icon(
                  view.url == current?.url
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(view.label),
                onTap: () => Navigator.of(context).pop(view),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await ref.read(selectedViewNotifierProvider.notifier).select(chosen);
    }
  }
}

/// US-JX-20: Home is showing the last saved listing because the server
/// can't be reached. Anything that changes Jenkins needs the connection
/// back; job detail says so itself when opened.
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAt = ref.watch(offlineSnapshotNotifierProvider);
    if (savedAt == null) return const SizedBox.shrink();
    final local = savedAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InlineAlert(
        icon: Icons.cloud_off_rounded,
        tone: StatusTone.neutral,
        message:
            'Offline — showing data from ${two(local.hour)}:'
            '${two(local.minute)}. Builds can\'t be started or changed '
            'until you\'re back online.',
      ),
    );
  }
}
