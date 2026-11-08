import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';

part 'sonarqube_projects_notifier.g.dart';

/// The active credential's projects (`US-SQ-PROJ-01`).
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.
@riverpod
class SonarQubeProjectsNotifier extends _$SonarQubeProjectsNotifier {
  @override
  Future<List<SonarQubeProject>> build() async {
    final result = await ref.watch(sonarQubeRepositoryProvider).fetchProjects();
    return result.fold((projects) => projects, (failure) => throw failure);
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

/// Projects matching the search, by name or key, case-insensitively.
@riverpod
List<SonarQubeProject> filteredSonarQubeProjects(Ref ref) {
  final projects =
      ref.watch(sonarQubeProjectsNotifierProvider).value ??
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
