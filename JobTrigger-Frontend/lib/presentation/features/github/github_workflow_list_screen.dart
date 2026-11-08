import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_pill.dart';
import '../../common_widgets/status_tile.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'github_workflows_notifier.dart';

/// A single repo's workflow list (`US-GH-REPO-02`). Pushed from
/// `GitHubRepoScreen` with a [GitHubRepo] as `extra`, pinned to the root
/// navigator like `JobDetailScreen`/`BuildLogScreen` -- a drill-down, not
/// a tab-shell root.
///
/// A tile opens the workflow's recent runs (`US-GH-RUN-01`). The P14
/// design's "Run" buttons wait for the trigger flow (P8-14/17).
class GitHubWorkflowListScreen extends ConsumerWidget {
  const GitHubWorkflowListScreen({required this.repo, super.key});

  final GitHubRepo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(
      gitHubWorkflowsNotifierProvider(repo.owner, repo.name),
    );

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
                      repo.owner,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(repo.name, style: textTheme.headlineMedium),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: workflowsAsync.when(
                  data: (workflows) =>
                      _WorkflowListView(repo: repo, workflows: workflows),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref
                          .read(
                            gitHubWorkflowsNotifierProvider(
                              repo.owner,
                              repo.name,
                            ).notifier,
                          )
                          .refresh(),
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

class _WorkflowListView extends ConsumerWidget {
  const _WorkflowListView({required this.repo, required this.workflows});

  final GitHubRepo repo;
  final List<GitHubWorkflow> workflows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workflows.isEmpty) {
      return const _EmptyState();
    }
    final t = AppTokens.of(context);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(gitHubWorkflowsNotifierProvider(repo.owner, repo.name).notifier)
          .refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            sliver: SliverToBoxAdapter(
              child: SectionLabel('Workflows', trailing: '${workflows.length}'),
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
                itemCount: workflows.length,
                itemBuilder: (context, index) => _WorkflowTile(
                  workflow: workflows[index],
                  onTap: () => context.push(
                    AppRoutes.githubRuns,
                    extra: (repo, workflows[index]),
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
          Icon(Icons.bolt_outlined, size: 40, color: t.textMuted),
          const SizedBox(height: 12),
          Text(
            'No workflows found',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

/// One workflow: its name, its file, and whether it's disabled. Tapping
/// opens its recent runs (`US-GH-RUN-01`), disabled workflows included —
/// their history is still worth reading.
class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({required this.workflow, required this.onTap});

  final GitHubWorkflow workflow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    // AUD-62's rule: availability is shown by the tile and the pill, never
    // by fading the text below its contrast floor.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            StatusTile(
              tone: workflow.isActive ? StatusTone.running : StatusTone.neutral,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workflow.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    workflow.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(
                      textTheme.bodySmall,
                    ).copyWith(fontSize: 12, color: t.textMuted),
                  ),
                ],
              ),
            ),
            if (!workflow.isActive) ...[
              const SizedBox(width: 8),
              const StatusPill(label: 'Disabled', tone: StatusTone.neutral),
            ],
          ],
        ),
      ),
    );
  }
}
