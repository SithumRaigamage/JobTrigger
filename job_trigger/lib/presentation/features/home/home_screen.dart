import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/status_indicator.dart';
import '../../navigation/app_routes.dart';
import 'filtered_jobs_provider.dart';
import 'folder_breadcrumb_notifier.dart';
import 'job_search_notifier.dart';
import 'job_tree_notifier.dart';

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
    final jobTreeAsync = ref.watch(jobTreeNotifierProvider);
    final breadcrumb = ref.watch(folderBreadcrumbNotifierProvider);

    return PopScope(
      canPop: breadcrumb.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(folderBreadcrumbNotifierProvider.notifier).navigateBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(breadcrumb.isEmpty ? 'Jobs' : breadcrumb.last.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'History',
              onPressed: () => context.push(AppRoutes.globalHistory),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () => context.push(AppRoutes.settings),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'Profile',
              onPressed: () => context.push(AppRoutes.profile),
            ),
          ],
        ),
        body: Column(
          children: [
            const _SearchField(),
            const _BreadcrumbHeader(),
            Expanded(
              child: jobTreeAsync.when(
                data: (_) => const _JobListView(),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: ConnectionErrorView(
                    message: describeError(error),
                    onRetry: () =>
                        ref.read(jobTreeNotifierProvider.notifier).refresh(),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
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
                                text: folder.name,
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
  const _JobListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(filteredJobsProvider);
    final query = ref.watch(jobSearchNotifierProvider);

    if (jobs.isEmpty) {
      return _EmptyState(query: query);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(jobTreeNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _JobTile(job: jobs[index]),
        ),
      ),
    );
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
  const _JobTile({required this.job});

  final JenkinsJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (job.isFolder) {
            ref
                .read(folderBreadcrumbNotifierProvider.notifier)
                .navigateInto(job);
          } else {
            context.push(AppRoutes.jobDetail, extra: job);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  child: const Icon(
                    Icons.folder,
                    color: Colors.orange,
                    size: 20,
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
                    Text(
                      job.name,
                      style: Theme.of(context).textTheme.bodyMedium,
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          )
                        else if (!job.isFolder)
                          Text(
                            'No builds',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }
}
