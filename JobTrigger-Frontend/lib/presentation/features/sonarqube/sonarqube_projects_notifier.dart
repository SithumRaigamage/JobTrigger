import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';

part 'sonarqube_projects_notifier.g.dart';

/// The projects loaded so far (`US-SQ-PROJ-01`), and whether more exist.
class SonarQubeProjects {
  const SonarQubeProjects({
    required this.projects,
    required this.total,
    required this.pagesLoaded,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final List<SonarQubeProject> projects;

  /// How many projects the server says the user can browse.
  final int total;
  final int pagesLoaded;
  final bool isLoadingMore;

  /// Set when the last "load more" failed, so the screen can say so and
  /// offer a retry instead of silently ending the list.
  final Object? loadMoreFailure;

  bool get hasMore => projects.length < total;

  SonarQubeProjects copyWith({
    List<SonarQubeProject>? projects,
    int? total,
    int? pagesLoaded,
    bool? isLoadingMore,
    Object? loadMoreFailure,
    bool clearFailure = false,
  }) => SonarQubeProjects(
    projects: projects ?? this.projects,
    total: total ?? this.total,
    pagesLoaded: pagesLoaded ?? this.pagesLoaded,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}

/// The active credential's projects, a page at a time.
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.
@riverpod
class SonarQubeProjectsNotifier extends _$SonarQubeProjectsNotifier {
  @override
  Future<SonarQubeProjects> build() async {
    final result = await ref.watch(sonarQubeRepositoryProvider).fetchProjects();
    final page = result.fold((page) => page, (failure) => throw failure);
    return SonarQubeProjects(
      projects: page.projects,
      total: page.total,
      pagesLoaded: 1,
    );
  }

  /// Appends the next page. A failure keeps what's loaded and records the
  /// failure instead of replacing the list with an error screen.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearFailure: true),
    );
    final result = await ref
        .read(sonarQubeRepositoryProvider)
        .fetchProjects(page: current.pagesLoaded + 1);
    if (!ref.mounted) return;
    state = AsyncData(switch (result) {
      Ok(value: final page) => _merged(current, page),
      Err(:final error) => current.copyWith(
        isLoadingMore: false,
        loadMoreFailure: error,
      ),
    });
  }

  /// The loaded projects plus [page], without repeating one that moved
  /// between pages while the user scrolled.
  static SonarQubeProjects _merged(
    SonarQubeProjects current,
    SonarQubeProjectsPage page,
  ) {
    final known = {for (final p in current.projects) p.key};
    final added = [
      for (final p in page.projects)
        if (known.add(p.key)) p,
    ];
    final projects = [...current.projects, ...added];
    return SonarQubeProjects(
      projects: projects,
      // A page that added nothing means there is nothing more to get, whatever
      // the total says (projects deleted meanwhile); stop rather than loop.
      total: added.isEmpty ? projects.length : page.total,
      pagesLoaded: current.pagesLoaded + 1,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// The search box's text (`US-SQ-PROJ-02`).
@riverpod
class SonarQubeProjectSearch extends _$SonarQubeProjectSearch {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

/// Loaded projects matching the search, by name or key, case-insensitively.
@riverpod
List<SonarQubeProject> filteredSonarQubeProjects(Ref ref) {
  final projects =
      ref.watch(sonarQubeProjectsNotifierProvider).value?.projects ??
      const <SonarQubeProject>[];
  final query = ref.watch(sonarQubeProjectSearchProvider).trim().toLowerCase();
  if (query.isEmpty) return projects;
  return projects
      .where(
        (p) =>
            p.name.toLowerCase().contains(query) ||
            p.key.toLowerCase().contains(query),
      )
      .toList();
}
