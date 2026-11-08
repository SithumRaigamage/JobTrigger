import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_project_summary.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/credential_load_gate.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/no_active_sonarqube_credential_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/status_pill.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_gate_style.dart';
import 'sonarqube_last_analysis.dart';
import 'sonarqube_projects_notifier.dart';
import 'sonarqube_summaries_notifier.dart';
import 'sonarqube_summaries_sync.dart';

/// The Home tab while SonarQube is the active tool (`US-SQ-PROJ-01..03`): a
/// searchable, sortable list of the credential's projects, each with its
/// quality-gate verdict and headline numbers; a tap opens the project.
class SonarQubeProjectScreen extends ConsumerWidget {
  const SonarQubeProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    if (credential == null) {
      // Not "no credential" until the saved list says so: it may still be
      // loading, or have failed to load.
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CredentialLoadGate(
              saved: ref.watch(sonarQubeCredentialsNotifierProvider),
              none: const NoActiveSonarQubeCredentialView(),
              onRetry: () {
                ref.invalidate(sonarQubeCredentialsNotifierProvider);
                ref.invalidate(activeSonarQubeCredentialNotifierProvider);
              },
            ),
          ),
        ),
      );
    }

    // Loads the cards' numbers as projects arrive.
    ref.watch(sonarQubeSummariesSyncProvider);
    final projectsAsync = ref.watch(sonarQubeProjectsNotifierProvider);
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      credential.label,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text('Projects', style: textTheme.headlineLarge),
                    ),
                    const SizedBox(height: 14),
                    Semantics(
                      label: 'Search projects',
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search projects',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (query) => ref
                            .read(sonarQubeProjectSearchProvider.notifier)
                            .setQuery(query),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _Controls(),
                  ],
                ),
              ),
              Expanded(
                child: projectsAsync.when(
                  data: (_) => const _ProjectList(),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref
                          .read(sonarQubeProjectsNotifierProvider.notifier)
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

/// "Failing only" and the sort order.
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failingOnly = ref.watch(sonarQubeFailingOnlyProvider);
    final sort = ref.watch(sonarQubeProjectSortNotifierProvider);
    final t = AppTokens.of(context);
    return Row(
      children: [
        FilterChip(
          label: const Text('Failing only'),
          selected: failingOnly,
          onSelected: (_) =>
              ref.read(sonarQubeFailingOnlyProvider.notifier).toggle(),
        ),
        const Spacer(),
        PopupMenuButton<SonarQubeProjectSort>(
          tooltip: 'Sort projects',
          initialValue: sort,
          onSelected: (value) => ref
              .read(sonarQubeProjectSortNotifierProvider.notifier)
              .set(value),
          itemBuilder: (_) => [
            for (final option in SonarQubeProjectSort.values)
              PopupMenuItem(value: option, child: Text(option.label)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 18, color: t.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Sort: ${sort.label}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectList extends ConsumerWidget {
  const _ProjectList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(filteredSonarQubeProjectsProvider);
    final query = ref.watch(sonarQubeProjectSearchProvider);
    final failingOnly = ref.watch(sonarQubeFailingOnlyProvider);
    final summaries = ref.watch(sonarQubeSummariesNotifierProvider);
    final t = AppTokens.of(context);
    final loaded = ref.watch(sonarQubeProjectsNotifierProvider).value;
    final notifier = ref.read(sonarQubeProjectsNotifierProvider.notifier);

    if (projects.isEmpty) {
      // A search that finds nothing among the loaded projects may still have
      // a match on a page that isn't loaded yet.
      final moreToSearch = query.isNotEmpty && (loaded?.hasMore ?? false);
      final message = failingOnly && query.isEmpty
          ? (summaries.isLoading
                ? 'Checking quality gates…'
                : 'No projects are failing their quality gate')
          : (query.isEmpty ? 'No projects found' : 'No results for "$query"');
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 40, color: t.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
            ),
            if (moreToSearch) ...[
              const SizedBox(height: 8),
              Text(
                'Only ${loaded!.projects.length} of ${loaded.total} projects '
                'are loaded.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
              TextButton(
                onPressed: notifier.loadMore,
                child: const Text('Load more'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) notifier.loadMore();
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            16 + glassNavBarClearance(context),
          ),
          itemCount: projects.length + 1,
          itemBuilder: (context, index) => index < projects.length
              ? _ProjectTile(project: projects[index])
              : _Footer(
                  loaded: loaded,
                  searching: query.isNotEmpty,
                  onLoadMore: notifier.loadMore,
                ),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
        ),
      ),
    );
  }
}

/// What the list did not show: that more projects exist, that loading them
/// failed, or that the search only covers what is loaded.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.loaded,
    required this.searching,
    required this.onLoadMore,
  });

  final SonarQubeProjects? loaded;
  final bool searching;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final state = loaded;
    if (state == null) return const SizedBox.shrink();
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreFailure != null) {
      return Column(
        children: [
          Text(
            describeError(state.loadMoreFailure!),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          TextButton(onPressed: onLoadMore, child: const Text('Load more')),
        ],
      );
    }
    if (!state.hasMore) return const SizedBox(height: 8);
    return Column(
      children: [
        Text(
          'Showing ${state.projects.length} of ${state.total} projects'
          '${searching ? '. Search covers only these.' : ''}',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: t.textMuted),
        ),
        TextButton(onPressed: onLoadMore, child: const Text('Load more')),
      ],
    );
  }
}

/// One project: its name and key, its quality-gate verdict, the headline
/// numbers, and when it was last analysed. A tap opens the project.
class _ProjectTile extends ConsumerWidget {
  const _ProjectTile({required this.project});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final summary = ref.watch(
      sonarQubeSummariesNotifierProvider.select((s) => s.byKey[project.key]),
    );
    return Semantics(
      button: true,
      label:
          '${project.name}, ${project.key}'
          '${summary == null ? '' : ', quality gate ${gateLabel(summary.gate)}'}',
      excludeSemantics: true,
      child: GlassSurface.card(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push(AppRoutes.sonarqubeProject, extra: project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                ),
                if (summary != null) ...[
                  const SizedBox(width: 8),
                  StatusPill(
                    label: gateLabel(summary.gate),
                    tone: gateTone(summary.gate),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              project.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                textTheme.bodySmall,
              ).copyWith(fontSize: 12, color: t.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (summary != null) Expanded(child: _Stats(summary: summary)),
                if (summary == null) const Spacer(),
                LastAnalysisText(
                  project: project,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bugs, vulnerabilities, code smells and coverage as four small figures. A
/// count above zero for bugs or vulnerabilities is drawn in the failure
/// colour; a figure the server did not compute is a dash, not a zero.
class _Stats extends StatelessWidget {
  const _Stats({required this.summary});

  final SonarQubeProjectSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final bad = t.failure.foreground;
    String count(int? n) => n == null ? '—' : '$n';
    final coverage = summary.coverage;
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        _Stat(
          icon: Icons.bug_report_outlined,
          text: count(summary.bugs),
          label: 'bugs',
          color: (summary.bugs ?? 0) > 0 ? bad : null,
        ),
        _Stat(
          icon: Icons.lock_open_rounded,
          text: count(summary.vulnerabilities),
          label: 'vulnerabilities',
          color: (summary.vulnerabilities ?? 0) > 0 ? bad : null,
        ),
        _Stat(
          icon: Icons.cleaning_services_outlined,
          text: count(summary.codeSmells),
          label: 'code smells',
        ),
        _Stat(
          icon: Icons.pie_chart_outline_rounded,
          text: coverage == null ? '—' : '${coverage.round()}%',
          label: 'coverage',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.text,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String text;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final tone = color ?? t.textSecondary;
    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tone),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: tone,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
