import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/github/github_repo.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/no_active_github_credential_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import '../../../data/credentials/active_github_credential_notifier.dart';
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
///
/// Laid out to the P14 design (`UI-UX/screens/07-home-github-repos`): the
/// active credential as a chip, the title, search, and a card per repo.
class GitHubRepoScreen extends ConsumerWidget {
  const GitHubRepoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCredential = ref.watch(activeGitHubCredentialNotifierProvider);
    if (activeCredential == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: NoActiveGitHubCredentialView())),
      );
    }

    final reposAsync = ref.watch(gitHubReposNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _AccountChip(label: activeCredential.label),
                    ),
                    const SizedBox(height: 14),
                    Semantics(
                      header: true,
                      child: Text(
                        'Repositories',
                        style: textTheme.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SearchField(),
                  ],
                ),
              ),
              Expanded(
                child: reposAsync.when(
                  data: (_) => const _RepoListView(),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref
                          .read(gitHubReposNotifierProvider.notifier)
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

/// The GitHub credential in use. Credentials are switched in Settings, so
/// that's where it leads.
class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Semantics(
      button: true,
      label: 'GitHub account $label. Switch account',
      excludeSemantics: true,
      child: Material(
        color: t.card,
        shape: StadiumBorder(side: BorderSide(color: t.cardBorder)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.go(AppRoutes.settings),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: t.text,
                    child: Text(
                      label.isEmpty ? '?' : label[0].toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: t.background,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: t.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Search repositories',
      child: TextField(
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search repositories',
          prefixIcon: Icon(Icons.search_rounded, size: 20),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          16 + glassNavBarClearance(context),
        ),
        itemCount: repos.length,
        itemBuilder: (context, index) => _RepoTile(repo: repos[index]),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 40, color: t.textMuted),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? 'No repositories found' : 'No results for "$query"',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
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
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface.card(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(AppRoutes.githubWorkflows, extra: repo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${repo.owner}/',
                        style: TextStyle(color: t.textMuted),
                      ),
                      TextSpan(text: repo.name),
                    ],
                  ),
                  style: textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  repo.private ? 'Private' : 'Public',
                  style: textTheme.labelSmall?.copyWith(
                    color: t.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.call_split_rounded, size: 14, color: t.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  repo.defaultBranch,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  semanticsLabel: 'Default branch ${repo.defaultBranch}',
                  style: AppTypography.mono(
                    textTheme.bodySmall,
                  ).copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
