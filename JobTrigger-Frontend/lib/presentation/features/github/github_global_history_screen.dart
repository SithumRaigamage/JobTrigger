import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/github/github_workflow.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'github_global_history_notifier.dart';
import 'github_run_history_screen.dart' show GitHubRunHistoryTile;

/// Recent runs across your most recently updated repos (`US-GH-HIST-02`).
/// GitHub has no single endpoint for this, so it asks each of the first
/// [globalHistoryRepoCap] repos and merges the answers; the screen says
/// plainly how many repos it left out or couldn't read.
class GitHubGlobalHistoryScreen extends ConsumerWidget {
  /// [isTab] is true when this is the History tab's root: there is nothing
  /// to go back to, so no back button.
  const GitHubGlobalHistoryScreen({this.isTab = false, super.key});

  final bool isTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(gitHubGlobalHistoryNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isTab)
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
                padding: EdgeInsets.fromLTRB(20, isTab ? 16 : 4, 20, 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    'Recent activity',
                    style: textTheme.headlineMedium,
                  ),
                ),
              ),
              Expanded(
                child: feedAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref
                          .read(gitHubGlobalHistoryNotifierProvider.notifier)
                          .refresh(),
                    ),
                  ),
                  data: (feed) {
                    if (feed.entries.isEmpty) {
                      return Center(
                        child: Text(
                          'No recent runs',
                          style: textTheme.bodyMedium?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(gitHubGlobalHistoryNotifierProvider.notifier)
                          .refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          16 + glassNavBarClearance(context),
                        ),
                        children: [
                          for (final entry in feed.entries)
                            GitHubRunHistoryTile(
                              run: entry.run,
                              repoLabel: entry.repo.fullName,
                              onTap: () => context.push(
                                AppRoutes.githubRunDetail,
                                extra: (
                                  entry.repo,
                                  // The detail screen only needs the
                                  // workflow's name and id for its header.
                                  GitHubWorkflow(
                                    id: entry.run.workflowId ?? 0,
                                    name: entry.run.workflowName ?? 'Workflow',
                                    path: '',
                                    state: 'active',
                                  ),
                                  entry.run,
                                ),
                              ),
                            ),
                          _Coverage(feed: feed),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the feed did not cover, so a short list is never mistaken for a
/// complete one.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.feed});

  final GlobalRunFeed feed;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final notes = [
      'Showing your ${feed.reposAsked} most recently updated '
          '${feed.reposAsked == 1 ? 'repository' : 'repositories'}.',
      if (feed.reposSkipped > 0)
        '${feed.reposSkipped} more ${feed.reposSkipped == 1 ? 'was' : 'were'} '
            'left out to stay within GitHub\'s rate limit.',
      if (feed.reposFailed > 0)
        '${feed.reposFailed} could not be read'
            '${feed.firstFailure == null ? '' : ': ${feed.firstFailure!.message}'}',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        notes.join(' '),
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(color: t.textMuted),
      ),
    );
  }
}
