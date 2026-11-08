import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow.dart';
import '../../../domain/github/github_workflow_run.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/status_tile.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'github_run_history_notifier.dart';
import 'github_runs_screen.dart' show toneForRunOutcome;

/// A workflow's full run history (`US-GH-HIST-01`): the same runs as the
/// runs list, paged all the way back, laid out like the Jenkins history
/// (`HistoryTile`'s look: status tile, title, state, when).
class GitHubRunHistoryScreen extends ConsumerWidget {
  const GitHubRunHistoryScreen({
    required this.repo,
    required this.workflow,
    super.key,
  });

  final GitHubRepo repo;
  final GitHubWorkflow workflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gitHubRunHistoryNotifierProvider(
      repo.owner,
      repo.name,
      workflow.id,
    );
    final pagesAsync = ref.watch(provider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${repo.fullName} · ${workflow.name}',
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text('History', style: textTheme.headlineMedium),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: pagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.read(provider.notifier).refresh(),
                    ),
                  ),
                  data: (pages) => _HistoryList(
                    repo: repo,
                    workflow: workflow,
                    pages: pages,
                    onRefresh: () => ref.read(provider.notifier).refresh(),
                    onLoadMore: () => ref.read(provider.notifier).loadMore(),
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

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.repo,
    required this.workflow,
    required this.pages,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final GitHubRepo repo;
  final GitHubWorkflow workflow;
  final GitHubRunPages pages;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    if (pages.runs.isEmpty) {
      return Center(
        child: Text(
          'No runs yet',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 400) onLoadMore();
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            16 + glassNavBarClearance(context),
          ),
          children: [
            for (final run in pages.runs)
              GitHubRunHistoryTile(
                run: run,
                onTap: () => context.push(
                  AppRoutes.githubRunDetail,
                  extra: (repo, workflow, run),
                ),
              ),
            _Footer(pages: pages, onLoadMore: onLoadMore),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.pages, required this.onLoadMore});

  final GitHubRunPages pages;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (pages.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (pages.loadMoreFailure != null) {
      return Column(
        children: [
          Text(
            describeError(pages.loadMoreFailure!),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          TextButton(onPressed: onLoadMore, child: const Text('Load more')),
        ],
      );
    }
    if (pages.hasMore) {
      return TextButton(onPressed: onLoadMore, child: const Text('Load more'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Start of history',
          style: textTheme.bodySmall?.copyWith(color: t.textMuted),
        ),
      ),
    );
  }
}

/// One run in the history: `HistoryTile`'s layout adapted to a
/// [GitHubWorkflowRun] — status tile, "title #n", the state in its status
/// colour with event and branch, and when it started.
class GitHubRunHistoryTile extends StatelessWidget {
  const GitHubRunHistoryTile({required this.run, this.onTap, super.key});

  final GitHubWorkflowRun run;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final tone = toneForRunOutcome(run.outcome);
    final created = run.createdAt;
    final detail = [
      run.label,
      if (run.event.isNotEmpty) run.event,
      if (run.branch != null) run.branch!,
    ].join(' · ');
    final mono = AppTypography.mono(textTheme.bodySmall).copyWith(fontSize: 12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '${run.title}, run ${run.runNumber}, $detail',
        excludeSemantics: true,
        child: GlassSurface.card(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                StatusTile(tone: tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${run.title} '),
                            TextSpan(
                              text: '#${run.runNumber}',
                              style: AppTypography.mono(
                                null,
                              ).copyWith(color: t.textMuted),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: t.status(tone).foreground,
                        ),
                      ),
                      if (created != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${dayLabel(created)} ${clockTime(created)}',
                          style: mono,
                        ),
                      ],
                    ],
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
