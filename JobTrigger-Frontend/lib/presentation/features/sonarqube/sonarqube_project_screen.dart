import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/credential_load_gate.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/no_active_sonarqube_credential_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_projects_notifier.dart';

/// The Home tab while SonarQube is the active tool (`US-SQ-PROJ-01/02`): a
/// searchable list of the credential's projects; a tap opens the project's
/// quality gate and measures.
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

class _ProjectList extends ConsumerWidget {
  const _ProjectList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(filteredSonarQubeProjectsProvider);
    final query = ref.watch(sonarQubeProjectSearchProvider);
    final t = AppTokens.of(context);
    final loaded = ref.watch(sonarQubeProjectsNotifierProvider).value;
    final notifier = ref.read(sonarQubeProjectsNotifierProvider.notifier);

    if (projects.isEmpty) {
      // A search that finds nothing among the loaded projects may still have
      // a match on a page that isn't loaded yet.
      final moreToSearch = query.isNotEmpty && (loaded?.hasMore ?? false);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 40, color: t.textMuted),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'No projects found' : 'No results for "$query"',
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

/// One project: its name, its key, and when it was last analysed. Tapping
/// opens its quality gate and measures.
class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final analysed = project.lastAnalysisDate;
    final when = analysed == null
        ? 'Never analyzed'
        : 'Analyzed ${relativeTime(analysed)}';
    return Semantics(
      label: '${project.name}, ${project.key}, $when',
      excludeSemantics: true,
      child: GlassSurface.card(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push(AppRoutes.sonarqubeProject, extra: project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              project.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                textTheme.bodySmall,
              ).copyWith(fontSize: 12, color: t.textMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: t.textMuted),
                const SizedBox(width: 6),
                Text(
                  when,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: t.textSecondary,
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
