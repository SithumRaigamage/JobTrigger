import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/github/github_repo.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/no_active_github_credential_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import '../settings/active_github_credential_notifier.dart';
import 'filtered_github_repos_provider.dart';
import 'github_repo_search_notifier.dart';
import 'github_repos_notifier.dart';

/// GitHub's "Home" — the repo list a GitHub credential's user lands on,
/// structurally parallel to `HomeScreen` but for a flat list (`US-GH-REPO-
/// 01`) rather than Jenkins' recursive folder tree, so there's no
/// breadcrumb/folder-navigation state here. Reached via the same
/// `AppRoutes.home` tab slot as `HomeScreen` -- see `app_router.dart`'s
/// tool-aware wrapper -- kept as a fully separate widget rather than a
/// conditional branch inside `HomeScreen` itself.
class GitHubRepoScreen extends ConsumerWidget {
  const GitHubRepoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCredential = ref.watch(activeGitHubCredentialNotifierProvider);
    if (activeCredential == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Tool Selection',
            onPressed: () => context.go(AppRoutes.toolSelection),
          ),
          title: const Text('Repositories'),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            child: const NoActiveGitHubCredentialView(),
          ),
        ),
      );
    }

    final reposAsync = ref.watch(gitHubReposNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Tool Selection',
          onPressed: () => context.go(AppRoutes.toolSelection),
        ),
        title: const Text('Repositories'),
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            const _SearchField(),
            Expanded(
              child: reposAsync.when(
                data: (_) => const _RepoListView(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: ConnectionErrorView(
                    message: describeError(error),
                    onRetry: () =>
                        ref.read(gitHubReposNotifierProvider.notifier).refresh(),
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

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Repositories',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: (query) =>
            ref.read(gitHubRepoSearchNotifierProvider.notifier).setQuery(query),
      ),
    );
  }
}

class _RepoListView extends ConsumerWidget {
  const _RepoListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repos = ref.watch(filteredGitHubReposProvider);
    final query = ref.watch(gitHubRepoSearchNotifierProvider);

    if (repos.isEmpty) {
      return _EmptyState(query: query);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(gitHubReposNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + glassNavBarClearance(context),
        ),
        itemCount: repos.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RepoTile(repo: repos[index]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 40,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? 'No repositories found' : 'No results for "$query"',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoTile extends StatelessWidget {
  const _RepoTile({required this.repo});

  final GitHubRepo repo;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(12),
      onTap: () =>
          context.push(AppRoutes.githubWorkflows, extra: repo),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              repo.private ? Icons.lock_outline : Icons.book_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repo.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        repo.defaultBranch,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                    if (repo.private) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Private',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
