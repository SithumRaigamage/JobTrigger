import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_insights_notifiers.dart';
import 'sonarqube_issue_widgets.dart';

/// `US-SQ-ISSUES-01`: the open issues assigned to the token's user, across
/// every project they can browse. Read-only, like the rest of the epic; the
/// row names its project so nothing has to be looked up by hand.
class SonarQubeMyIssuesScreen extends ConsumerWidget {
  const SonarQubeMyIssuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(sonarQubeMyIssuesNotifierProvider);
    final notifier = ref.read(sonarQubeMyIssuesNotifierProvider.notifier);
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
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Across every project',
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          Semantics(
                            header: true,
                            child: Text(
                              'My issues',
                              style: textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: issuesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: notifier.refresh,
                    ),
                  ),
                  data: (loaded) => RefreshIndicator(
                    onRefresh: notifier.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        16 + glassNavBarClearance(context),
                      ),
                      children: [
                        SonarQubeIssueFilterChips(
                          filter: loaded.filter,
                          onChanged: notifier.setFilter,
                        ),
                        const SizedBox(height: 12),
                        if (loaded.issues.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              'Nothing is assigned to you',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            loaded.issues.length == loaded.total
                                ? '${loaded.total} open '
                                      '${loaded.total == 1 ? 'issue' : 'issues'}'
                                : '${loaded.issues.length} of '
                                      '${loaded.total} open issues',
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final issue in loaded.issues)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SonarQubeCrossProjectIssueCard(
                                issue: issue,
                              ),
                            ),
                          if (loaded.hasMore)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: OutlinedButton(
                                onPressed: loaded.loadingMore
                                    ? null
                                    : notifier.loadMore,
                                child: Text(
                                  loaded.loadingMore ? 'Loading…' : 'Load more',
                                ),
                              ),
                            ),
                        ],
                      ],
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
