import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/status_pill.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_issues_notifier.dart';

/// A project's open issues (`US-SQ-QUALITY-03`): filter chips for type and
/// severity that re-query the server, a list of what's wrong and where, and
/// "load more" for the rest.
class SonarQubeIssuesScreen extends ConsumerWidget {
  const SonarQubeIssuesScreen({required this.project, super.key});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesProvider = sonarQubeIssuesNotifierProvider(project.key);
    final filterProvider = sonarQubeIssueFilterNotifierProvider(project.key);
    final issuesAsync = ref.watch(issuesProvider);
    final filter = ref.watch(filterProvider);
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
                      project.name,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text('Issues', style: textTheme.headlineMedium),
                    ),
                  ],
                ),
              ),
              _FilterBar(
                filter: filter,
                onType: (type) =>
                    ref.read(filterProvider.notifier).toggleType(type),
                onSeverity: (s) =>
                    ref.read(filterProvider.notifier).toggleSeverity(s),
                onClear: () => ref.read(filterProvider.notifier).clear(),
              ),
              Expanded(
                child: issuesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () =>
                          ref.read(issuesProvider.notifier).refresh(),
                    ),
                  ),
                  data: (issues) => _IssueList(
                    issues: issues,
                    filtered: !filter.isEmpty,
                    onRefresh: () =>
                        ref.read(issuesProvider.notifier).refresh(),
                    onLoadMore: () =>
                        ref.read(issuesProvider.notifier).loadMore(),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onType,
    required this.onSeverity,
    required this.onClear,
  });

  final SonarQubeIssueFilter filter;
  final ValueChanged<String> onType;
  final ValueChanged<String> onSeverity;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final type in sonarQubeIssueTypes)
            FilterChip(
              label: Text(sonarQubeIssueTypeLabel(type)),
              selected: filter.types.contains(type),
              onSelected: (_) => onType(type),
            ),
          for (final severity in sonarQubeIssueSeverities)
            FilterChip(
              label: Text(sonarQubeSeverityLabel(severity)),
              selected: filter.severities.contains(severity),
              onSelected: (_) => onSeverity(severity),
            ),
          if (!filter.isEmpty)
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({
    required this.issues,
    required this.filtered,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final SonarQubeIssues issues;
  final bool filtered;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (issues.issues.isEmpty) {
      return Center(
        child: Text(
          filtered ? 'No issues match these filters' : 'No issues found',
          style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) onLoadMore();
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + glassNavBarClearance(context),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${issues.total} ${issues.total == 1 ? 'issue' : 'issues'}',
                style: textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
            ),
            for (final issue in issues.issues) _IssueTile(issue: issue),
            _Footer(issues: issues, onLoadMore: onLoadMore),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.issues, required this.onLoadMore});

  final SonarQubeIssues issues;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (issues.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (issues.loadMoreFailure != null) {
      return Column(
        children: [
          Text(
            describeError(issues.loadMoreFailure!),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          TextButton(onPressed: onLoadMore, child: const Text('Load more')),
        ],
      );
    }
    if (issues.hasMore) {
      return TextButton(onPressed: onLoadMore, child: const Text('Load more'));
    }
    if (issues.total > issues.issues.length) {
      // SonarQube stops paging at 10,000 results.
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Showing the first ${issues.issues.length}. Narrow the filters to '
          'see the rest.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: t.textMuted),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

StatusTone _toneForSeverity(String severity) => switch (severity) {
  'BLOCKER' || 'CRITICAL' => StatusTone.failure,
  'MAJOR' => StatusTone.unstable,
  'MINOR' => StatusTone.paused,
  _ => StatusTone.neutral,
};

IconData _iconForType(String type) => switch (type) {
  'BUG' => Icons.bug_report_outlined,
  'VULNERABILITY' => Icons.lock_open_rounded,
  _ => Icons.cleaning_services_outlined,
};

/// One issue: type icon, the message, where it is, and its severity — as
/// words as well as colour (NFR-A11Y-03).
class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final SonarQubeIssue issue;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final tone = _toneForSeverity(issue.severity);
    final location = issue.location;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label:
            '${sonarQubeIssueTypeLabel(issue.type)}, '
            '${sonarQubeSeverityLabel(issue.severity)}. ${issue.message}'
            '${location == null ? '' : '. $location'}',
        excludeSemantics: true,
        child: GlassSurface.card(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconForType(issue.type), size: 18, color: t.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sonarQubeIssueTypeLabel(issue.type),
                      style: textTheme.labelMedium?.copyWith(
                        color: t.textMuted,
                      ),
                    ),
                  ),
                  StatusPill(
                    label: sonarQubeSeverityLabel(issue.severity),
                    tone: tone,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(issue.message, style: textTheme.bodyMedium),
              if (location != null) ...[
                const SizedBox(height: 6),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(
                    textTheme.bodySmall,
                  ).copyWith(fontSize: 12, color: t.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
