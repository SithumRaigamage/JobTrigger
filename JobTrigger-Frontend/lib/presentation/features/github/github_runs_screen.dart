import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow.dart';
import '../../../domain/github/github_workflow_run.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_pill.dart';
import '../../common_widgets/status_tile.dart';
import '../../navigation/main_scaffold.dart';
import 'github_runs_notifier.dart';
import 'github_trigger_sheet.dart';
import '../../navigation/app_routes.dart';

/// A workflow's recent runs (`US-GH-RUN-01`), read-only for now: trigger,
/// live status and cancel land with P8-14..17. Pushed from
/// `GitHubWorkflowListScreen` with `(GitHubRepo, GitHubWorkflow)` as
/// `extra`, on the root navigator like the other drill-downs.
class GitHubRunsScreen extends ConsumerWidget {
  const GitHubRunsScreen({
    required this.repo,
    required this.workflow,
    super.key,
  });

  final GitHubRepo repo;
  final GitHubWorkflow workflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = gitHubRunsNotifierProvider(
      repo.owner,
      repo.name,
      workflow.id,
    );
    final runsAsync = ref.watch(provider);
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
                      repo.fullName,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        workflow.name,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => showGitHubTriggerSheet(
                            context,
                            repo: repo,
                            workflow: workflow,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Run workflow'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            AppRoutes.githubHistory,
                            extra: (repo, workflow),
                          ),
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('History'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: runsAsync.when(
                  data: (runs) => _RunListView(
                    repo: repo,
                    workflow: workflow,
                    runs: runs,
                    onRefresh: () => ref.read(provider.notifier).refresh(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.read(provider.notifier).refresh(),
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

class _RunListView extends StatelessWidget {
  const _RunListView({
    required this.repo,
    required this.workflow,
    required this.runs,
    required this.onRefresh,
  });

  final GitHubRepo repo;
  final GitHubWorkflow workflow;
  final List<GitHubWorkflowRun> runs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) return const _EmptyState();
    final t = AppTokens.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            sliver: SliverToBoxAdapter(
              child: SectionLabel('Recent runs', trailing: '${runs.length}'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.cardBorder),
              ),
              sliver: SliverList.separated(
                itemCount: runs.length,
                itemBuilder: (context, index) => _RunTile(
                  run: runs[index],
                  onTap: () => context.push(
                    AppRoutes.githubRunDetail,
                    extra: (repo, workflow, runs[index]),
                  ),
                ),
                separatorBuilder: (_, _) => const Divider(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 16 + glassNavBarClearance(context)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 40, color: t.textMuted),
          const SizedBox(height: 12),
          Text(
            'No runs yet',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

/// [GitHubRunOutcome] → the app's shared status tone, so a GitHub run and a
/// Jenkins build read the same (`US-GH-RUN-01`'s UI note).
StatusTone toneForRunOutcome(GitHubRunOutcome outcome) => switch (outcome) {
  GitHubRunOutcome.success => StatusTone.success,
  GitHubRunOutcome.failure => StatusTone.failure,
  GitHubRunOutcome.running => StatusTone.running,
  GitHubRunOutcome.queued => StatusTone.paused,
  GitHubRunOutcome.attention => StatusTone.unstable,
  GitHubRunOutcome.neutral => StatusTone.neutral,
};

IconData _iconFor(GitHubRunOutcome outcome) => switch (outcome) {
  GitHubRunOutcome.success => Icons.check_rounded,
  GitHubRunOutcome.failure => Icons.close_rounded,
  GitHubRunOutcome.running => Icons.sync_rounded,
  GitHubRunOutcome.queued => Icons.schedule_rounded,
  GitHubRunOutcome.attention => Icons.priority_high_rounded,
  GitHubRunOutcome.neutral => Icons.remove_rounded,
};

/// One run: title, `#number · event · branch · age`, and a status pill.
/// Tapping opens the live run detail.
class _RunTile extends StatelessWidget {
  const _RunTile({required this.run, required this.onTap});

  final GitHubWorkflowRun run;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final outcome = run.outcome;
    final created = run.createdAt;
    final details = [
      '#${run.runNumber}',
      if (run.event.isNotEmpty) run.event,
      if (run.branch != null) run.branch!,
      if (created != null) relativeTime(created),
    ].join(' · ');

    return Semantics(
      label: '${run.title}, ${run.label}, $details',
      excludeSemantics: true,
      button: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              StatusTile(
                tone: toneForRunOutcome(outcome),
                icon: _iconFor(outcome),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(
                        textTheme.bodySmall,
                      ).copyWith(fontSize: 12, color: t.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: run.label, tone: toneForRunOutcome(outcome)),
            ],
          ),
        ),
      ),
    );
  }
}
