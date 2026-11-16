import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'dashboard_notifier.dart';

/// The unified home dashboard (`NR-02`): failing builds, running jobs,
/// pinned items and failing quality gates across Jenkins, GitHub Actions and
/// SonarQube on one screen.
///
/// Read-only. Every row opens the same detail screen its own tool already
/// has; nothing here triggers, cancels or approves a build, so each tool's
/// existing behaviour is untouched (`CLAUDE.md` §11).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardNotifierProvider);
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Dashboard',
                              style: textTheme.titleLarge,
                            ),
                          ),
                          Text(
                            _summary(data.value),
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Refresh',
                      onPressed: () =>
                          ref.invalidate(dashboardNotifierProvider),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: data.when(
                  skipLoadingOnRefresh: true,
                  data: (value) => _DashboardBody(data: value),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.invalidate(dashboardNotifierProvider),
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

  /// "2 failing · 3 running", or nothing while it loads.
  static String _summary(DashboardData? data) {
    if (data == null) return 'Across every tool';
    final parts = [
      if (data.failingCount > 0) '${data.failingCount} failing',
      if (data.runningCount > 0) '${data.runningCount} running',
      if (data.qualityCount > 0) '${data.qualityCount} gates failing',
    ];
    return parts.isEmpty ? 'All clear' : parts.join(' · ');
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sections = _sections(data);
    final notes = _notes(data);

    if (data.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: t.success.foreground,
            ),
            const SizedBox(height: 12),
            Text(
              'Nothing needs you right now',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Failing builds, running jobs and pinned items appear here '
              'across every tool you have set up.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
            if (notes.isNotEmpty) ...[const SizedBox(height: 24), ...notes],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        for (final (title, items) in sections) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(title, style: textTheme.titleMedium),
            ),
          ),
          _Group(items: items),
        ],
        if (notes.isNotEmpty) ...[const SizedBox(height: 24), ...notes],
      ],
    );
  }

  /// The groups that have rows, in the dashboard's order.
  static List<(String, List<DashboardItem>)> _sections(DashboardData data) {
    final byGroup = <DashboardGroup, List<DashboardItem>>{};
    for (final item in data.items) {
      byGroup.putIfAbsent(item.group, () => []).add(item);
    }
    return [
      for (final group in DashboardGroup.values)
        if (byGroup[group] case final items?) (group.title, items),
    ];
  }

  /// What isn't on the screen and why: a tool that was never set up, or one
  /// whose data couldn't be loaded this time.
  static List<Widget> _notes(DashboardData data) {
    return [
      for (final source in data.notSetUp)
        _Note(
          text: '${source.label} isn’t set up on this device.',
          icon: Icons.link_off_rounded,
        ),
      for (final MapEntry(key: source, value: failure) in data.failures.entries)
        _Note(
          text: '${source.label}: ${failure.message}',
          icon: Icons.error_outline_rounded,
        ),
    ];
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.items});

  final List<DashboardItem> items;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _ItemRow(item: item),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final DashboardItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final tone = t.status(item.group.tone);
    final open = _destination(item);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: open == null ? null : () => _open(context, item),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(item.group.icon, size: 20, color: tone.foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (open != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: t.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Which detail screen this row opens, or null when the thing it names no
  /// longer exists (a deleted job or pin).
  static String? _destination(DashboardItem item) {
    if (item.jenkinsJob != null) return AppRoutes.jobDetail;
    if (item.sonarProject != null) return AppRoutes.sonarqubeProject;
    if (item.githubRepo != null &&
        item.githubWorkflow != null &&
        item.githubRun != null) {
      return AppRoutes.githubRunDetail;
    }
    return null;
  }

  static void _open(BuildContext context, DashboardItem item) {
    if (item.jenkinsJob case final job?) {
      context.push(AppRoutes.jobDetail, extra: job);
      return;
    }
    if (item.sonarProject case final project?) {
      context.push(AppRoutes.sonarqubeProject, extra: project);
      return;
    }
    final repo = item.githubRepo;
    final workflow = item.githubWorkflow;
    final run = item.githubRun;
    if (repo != null && workflow != null && run != null) {
      context.push(AppRoutes.githubRunDetail, extra: (repo, workflow, run));
    }
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: t.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

extension on DashboardGroup {
  String get title => switch (this) {
    DashboardGroup.failing => 'Failing and broken',
    DashboardGroup.running => 'Running now',
    DashboardGroup.pinned => 'Pinned',
    DashboardGroup.quality => 'Quality gates',
  };

  IconData get icon => switch (this) {
    DashboardGroup.failing => Icons.error_outline_rounded,
    DashboardGroup.running => Icons.play_circle_outline_rounded,
    DashboardGroup.pinned => Icons.push_pin_outlined,
    DashboardGroup.quality => Icons.rule_rounded,
  };

  StatusTone get tone => switch (this) {
    DashboardGroup.failing => StatusTone.failure,
    DashboardGroup.running => StatusTone.running,
    DashboardGroup.pinned => StatusTone.neutral,
    DashboardGroup.quality => StatusTone.unstable,
  };
}

extension on DashboardSource {
  String get label => switch (this) {
    DashboardSource.jenkins => 'Jenkins',
    DashboardSource.githubActions => 'GitHub Actions',
    DashboardSource.sonarqube => 'SonarQube',
  };
}
