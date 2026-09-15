import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/github/github_repo_search_notifier.dart';

void main() {
  test('initial state is an empty query', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(gitHubRepoSearchNotifierProvider), '');
  });

  test('setQuery updates the state to the given query', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gitHubRepoSearchNotifierProvider.notifier).setQuery('foo');

    expect(container.read(gitHubRepoSearchNotifierProvider), 'foo');
  });

  test('clear resets the state to an empty query', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gitHubRepoSearchNotifierProvider.notifier).setQuery('foo');

    container.read(gitHubRepoSearchNotifierProvider.notifier).clear();

    expect(container.read(gitHubRepoSearchNotifierProvider), '');
  });
}
