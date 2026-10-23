import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../../data/credentials/active_server_notifier.dart';
import 'build_trends_card.dart';
import 'history_tile.dart';
import 'job_history_pages_notifier.dart';
import 'replay_sheet.dart';

/// Ported from `HistoryView.swift`, extended for US-JX-06: pages through
/// all of a job's history (loading more near the end of the list) and
/// filters by result or "started by me". Reuses `HistoryTile` (P5-16).
/// Laid out to the P14 design (`UI-UX/screens/13-job-history`).
class JobHistoryScreen extends ConsumerWidget {
  const JobHistoryScreen({super.key, required this.job});

  final JenkinsJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(jobHistoryPagesNotifierProvider(job.url));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ResponsiveCenter(
                child: pagesAsync.when(
                  data: (pages) => _HistoryList(job: job, pages: pages),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref
                          .read(
                            jobHistoryPagesNotifierProvider(job.url).notifier,
                          )
                          .refresh(),
                    ),
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

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.job, required this.pages});

  final JenkinsJob job;
  final HistoryPages pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(jobHistoryFilterNotifierProvider(job.url));
    final username = ref.watch(
      activeServerNotifierProvider.select((server) => server?.username),
    );
    final builds = filterHistory(pages.builds, filter, username: username);
    final notifier = ref.read(
      jobHistoryPagesNotifierProvider(job.url).notifier,
    );
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return NotificationListener<ScrollNotification>(
      // Load the next page a screen before the end, so scrolling rarely
      // waits on it.
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) notifier.loadMore();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.label,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        'Build history',
                        style: textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // US-JX-15, over everything loaded (not the filter).
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: BuildTrendsCard(builds: pages.builds),
              ),
            ),
            SliverToBoxAdapter(child: _FilterRow(jobUrl: job.url)),
            if (builds.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: DecoratedSliver(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.cardBorder),
                  ),
                  sliver: SliverList.separated(
                    itemCount: builds.length,
                    itemBuilder: (context, index) {
                      final build = builds[index];
                      return HistoryTile(
                        key: ValueKey(build.url),
                        jenkinsBuild: build,
                        grouped: true,
                        withDate: true,
                        onTap: () =>
                            context.push(AppRoutes.buildDetail, extra: build),
                        onReplay: () => _replay(context, build),
                      );
                    },
                    separatorBuilder: (_, _) => const Divider(),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _Footer(
                pages: pages,
                noMatches: builds.isEmpty,
                filtered: filter.isActive,
                onLoadMore: notifier.loadMore,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _replay(BuildContext context, JenkinsBuild build) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => ReplaySheet(job: job, build: build),
      );
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.jobUrl});

  final String jobUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(jobHistoryFilterNotifierProvider(jobUrl));
    final notifier = ref.read(
      jobHistoryFilterNotifierProvider(jobUrl).notifier,
    );
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        children: [
          // First, so it's visible without scrolling the chip row.
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('Started by me'),
              selected: filter.startedByMe,
              onSelected: (_) => notifier.toggleStartedByMe(),
            ),
          ),
          for (final result in HistoryResultFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(result.label),
                showCheckmark: false,
                selected: filter.result == result,
                onSelected: (_) => notifier.setResult(result),
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.pages,
    required this.noMatches,
    required this.filtered,
    required this.onLoadMore,
  });

  final HistoryPages pages;
  final bool noMatches;
  final bool filtered;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final loaded = pages.builds.length;
    final Widget content;
    if (pages.isLoadingMore) {
      content = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (loaded == 0) {
      content = const Text('No build history yet');
    } else if (noMatches && pages.hasMore) {
      // A filter can hide a whole page; let the user dig further back.
      content = Column(
        children: [
          Text('No matching builds in the last $loaded', style: style),
          TextButton(onPressed: onLoadMore, child: const Text('Load more')),
        ],
      );
    } else if (noMatches) {
      content = Text(
        filtered ? 'No builds match these filters' : 'No builds',
        style: style,
      );
    } else if (pages.hasMore) {
      content = TextButton(
        onPressed: onLoadMore,
        child: const Text('Load more'),
      );
    } else {
      content = Text('End of history · $loaded builds', style: style);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: content),
    );
  }
}
