import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import 'github_workflows_notifier.dart';

/// A single repo's workflow list (`US-GH-REPO-02`). Pushed from
/// `GitHubRepoScreen` with a [GitHubRepo] as `extra`, pinned to the root
/// navigator like `JobDetailScreen`/`BuildLogScreen` -- a drill-down, not
/// a tab-shell root.
///
/// Tiles are deliberately inert (no tap action): GH-RUN, the run list/
/// trigger flow a tap would lead to, doesn't exist yet
/// (`tasks/phase-8-github-actions.md`'s GH-RUN section). Wiring a tap here
/// with nowhere real to go would be a dead end, not a feature.
class GitHubWorkflowListScreen extends ConsumerWidget {
  const GitHubWorkflowListScreen({required this.repo, super.key});

  final GitHubRepo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(
      gitHubWorkflowsNotifierProvider(repo.owner, repo.name),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: Text(repo.name),
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            Expanded(
              child: workflowsAsync.when(
                data: (workflows) =>
                    _WorkflowListView(repo: repo, workflows: workflows),
                loading: () => const Center(child: CircularProgressIndicator()),
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

    return RefreshIndicator(
      onRefresh: () => ref
          .read(gitHubWorkflowsNotifierProvider(repo.owner, repo.name).notifier)
          .refresh(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + glassNavBarClearance(context),
        ),
        itemCount: workflows.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _WorkflowTile(workflow: workflows[index]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_motion_outlined,
            size: 40,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No workflows found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({required this.workflow});

  final GitHubWorkflow workflow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: workflow.isActive ? 1.0 : 0.6,
      child: GlassSurface.card(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (workflow.isActive ? colorScheme.primary : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bolt_outlined,
                color: workflow.isActive ? colorScheme.primary : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workflow.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workflow.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!workflow.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Disabled',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
