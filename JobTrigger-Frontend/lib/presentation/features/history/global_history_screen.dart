import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../domain/jenkins/history_entry.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/active_server_gate.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'global_history_notifier.dart';
import 'history_tile.dart';

/// Ported from `GlobalHistoryView.swift`, laid out to the P14 design
/// (`UI-UX/screens/08-global-history`): the latest build of every job,
/// filterable by result and grouped by the day it started.
class GlobalHistoryScreen extends ConsumerWidget {
  const GlobalHistoryScreen({super.key});

  /// The design's chips: the results people look for across all jobs.
  static const filters = [
    HistoryResultFilter.all,
    HistoryResultFilter.failed,
    HistoryResultFilter.running,
    HistoryResultFilter.success,
    HistoryResultFilter.unstable,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeServer = ref.watch(activeServerNotifierProvider);
    if (activeServer == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: ActiveServerGate())),
      );
    }

    final history = ref.watch(filteredGlobalHistoryProvider);
    final filter = ref.watch(globalHistoryFilterNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Semantics(
                  header: true,
                  child: Text('History', style: textTheme.headlineLarge),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (final option in filters) ...[
                      ChoiceChip(
                        label: Text(option.label),
                        selected: filter == option,
                        showCheckmark: false,
                        onSelected: (_) => ref
                            .read(globalHistoryFilterNotifierProvider.notifier)
                            .select(option),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: history.when(
                  data: (days) => days.isEmpty
                      ? _EmptyState(filter: filter)
                      : _Timeline(days: days),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref
                          .read(globalHistoryNotifierProvider.notifier)
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

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.days});

  final List<(DateTime, List<HistoryEntry>)> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(globalHistoryNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final (day, entries) in days) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              sliver: SliverToBoxAdapter(child: SectionLabel(dayLabel(day))),
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
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    return HistoryTile(
                      key: ValueKey(entry.id),
                      jenkinsBuild: entry.build,
                      jobName: entry.jobName,
                      grouped: true,
                      onTap: () => context.push(
                        AppRoutes.buildDetail,
                        extra: entry.build,
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const Divider(),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: SizedBox(height: 16 + glassNavBarClearance(context)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final HistoryResultFilter filter;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_outlined, size: 40, color: t.textMuted),
          const SizedBox(height: 12),
          Text(
            filter == HistoryResultFilter.all
                ? 'No build history yet'
                : 'No ${filter.label.toLowerCase()} builds',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
