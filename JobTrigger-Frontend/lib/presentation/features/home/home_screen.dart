import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/jenkins/branch_kind.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/no_active_server_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/status_indicator.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import '../settings/active_server_notifier.dart';
import 'folder_breadcrumb_notifier.dart';
import 'job_search_notifier.dart';
import 'multibranch_notifiers.dart';
import 'visible_jobs_provider.dart';

/// Ported from `HomeView.swift`. Doesn't port the swipe-to-trigger-build
/// action or the backend connectivity check — triggering builds is Phase 5
/// scope (`tasks/phase-5-build-execution-logs-history.md`), and the
/// backend-reachability banner isn't in any phase task list.
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
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Tool Selection',
            onPressed: () => context.go(AppRoutes.toolSelection),
          ),
          title: const Text('Jobs'),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            child: const NoActiveServerView(),
          ),
        ),
      );
    }

    final visibleJobs = ref.watch(visibleJobsProvider);
    final breadcrumb = ref.watch(folderBreadcrumbNotifierProvider);

    return PopScope(
      canPop: breadcrumb.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(folderBreadcrumbNotifierProvider.notifier).navigateBack();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Tool Selection',
            onPressed: () => context.go(AppRoutes.toolSelection),
          ),
          title: Text(breadcrumb.isEmpty ? 'Jobs' : breadcrumb.last.label),
          actions: [
            if (breadcrumb.isNotEmpty && breadcrumb.last.isScannable)
              _ScanActions(project: breadcrumb.last),
            // US-JX-09: why aren't builds starting?
            IconButton(
              icon: const Icon(Icons.pending_actions),
              tooltip: 'Build queue',
              onPressed: () => context.push(AppRoutes.queue),
            ),
          ],
        ),
        body: ResponsiveCenter(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.paddingOf(context).top + kToolbarHeight,
              ),
              const _SearchField(),
              const _BreadcrumbHeader(),
              Expanded(
                child: visibleJobs.when(
                  data: (jobs) => _JobListView(
                    jobs: jobs,
                    // Branch/PR/tag sections only when browsing (not
                    // searching) inside a multibranch project.
                    multibranch:
                        breadcrumb.isNotEmpty &&
                            breadcrumb.last.isMultibranch &&
                            ref.watch(jobSearchNotifierProvider).isEmpty
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
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Jobs',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: (query) =>
            ref.read(jobSearchNotifierProvider.notifier).setQuery(query),
      ),
    );
  }
}

class _BreadcrumbHeader extends ConsumerWidget {
  const _BreadcrumbHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(jobSearchNotifierProvider);
    final breadcrumb = ref.watch(folderBreadcrumbNotifierProvider);

    if (query.isEmpty && breadcrumb.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassSurface.card(
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: query.isNotEmpty
            ? Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Searching across all folders',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : Row(
                children: [
                  TextButton.icon(
                    onPressed: () => ref
                        .read(folderBreadcrumbNotifierProvider.notifier)
                        .navigateBack(),
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Home'),
                            for (final folder in breadcrumb) ...[
                              const TextSpan(text: ' / '),
                              TextSpan(
                                text: folder.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _JobListView extends ConsumerWidget {
  const _JobListView({required this.jobs, this.multibranch});

  final List<JenkinsJob> jobs;

  /// The multibranch project being browsed, if any: its jobs are grouped
  /// into branch / pull request / tag sections (US-JX-03).
  final FolderRef? multibranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(jobSearchNotifierProvider);

    if (jobs.isEmpty) {
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
                child: _EmptyState(query: query),
              ),
            ],
          ),
        ),
      );
    }

    final project = multibranch;
    // Grouping is additive: until (or if) the views load, show a flat list.
    final kinds = project == null
        ? null
        : ref.watch(branchKindsProvider(project.url)).value;
    final items = kinds == null ? jobs : _grouped(jobs, kinds);

    return RefreshIndicator(
      onRefresh: () => refreshVisibleJobs(ref),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + glassNavBarClearance(context),
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => switch (items[index]) {
          final JenkinsJob job => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // Search spans every folder, so say where each result lives
            // (AUD-33).
            child: _JobTile(job: job, showFolderPath: query.isNotEmpty),
          ),
          final String header => Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(header, style: Theme.of(context).textTheme.labelLarge),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  /// Section header strings interleaved with their jobs, in
  /// branches → pull requests → tags order, empty sections omitted.
  static List<Object> _grouped(
    List<JenkinsJob> jobs,
    Map<String, BranchKind> kinds,
  ) => [
    for (final kind in BranchKind.values)
      if (jobs.where((job) => (kinds[job.name] ?? BranchKind.branch) == kind)
          case final section when section.isNotEmpty) ...[
        kind.sectionTitle,
        ...section,
      ],
  ];
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 40,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? 'No jobs found' : 'No results for "$query"',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTile extends ConsumerWidget {
  const _JobTile({required this.job, this.showFolderPath = false});

  final JenkinsJob job;
  final bool showFolderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(12),
      onTap: () {
        if (job.isFolder) {
          ref.read(folderBreadcrumbNotifierProvider.notifier).navigateInto(job);
        } else {
          context.push(AppRoutes.jobDetail, extra: job);
        }
      },
      child: Row(
        children: [
          if (job.isFolder)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              // Distinct shapes, not just color (NFR-A11Y-03): a
              // multibranch project and an organization folder aren't
              // plain folders (US-JX-03).
              child: Icon(
                job.isMultibranch
                    ? Icons.account_tree
                    : job.isScannable
                    ? Icons.corporate_fare
                    : Icons.folder,
                color: Colors.orange,
                size: 20,
                semanticLabel: job.isMultibranch
                    ? 'Multibranch project'
                    : job.isScannable
                    ? 'Organization folder'
                    : 'Folder',
              ),
            )
          else
            SizedBox(
              width: 44,
              height: 44,
              child: Center(child: StatusIndicator(color: job.color)),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.label, style: Theme.of(context).textTheme.bodyMedium),
                if (showFolderPath && folderPathOf(job.url).isNotEmpty)
                  Text(
                    folderPathOf(job.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (job.lastBuild != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${job.lastBuild!.number}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      )
                    else if (!job.isFolder)
                      Text(
                        'No builds',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (job.description != null &&
                        job.description!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          job.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
