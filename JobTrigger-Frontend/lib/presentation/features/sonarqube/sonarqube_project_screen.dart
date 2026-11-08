import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_credential_gate.dart';
import 'sonarqube_project_card.dart';
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
    if (credential == null) return const SonarQubeCredentialGate();

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
              ? SonarQubeProjectCard(project: projects[index])
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
