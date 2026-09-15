import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_repo_search_notifier.g.dart';

@riverpod
class GitHubRepoSearchNotifier extends _$GitHubRepoSearchNotifier {
  @override
  String build() => '';

  void setQuery(String query) => state = query;

  void clear() => state = '';
}
