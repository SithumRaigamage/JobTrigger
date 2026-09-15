import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/settings/test_github_connection_notifier.dart';

// `test()` itself calls `testGitHubConnection()` directly — a top-level
// function that always builds its own internal `Dio` with no seam to
// inject a fake adapter (see `github_client_factory.dart`, and
// `tasks/phase-8-github-actions.md`'s P8-04 note, which already accepts
// this exact shape as untested for `testJenkinsConnection`/
// `testGitHubConnection`). Only the notifier's own state handling — not
// covered by that reasoning — is exercised here.
void main() {
  test('the initial state has no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      testGitHubConnectionNotifierProvider.future,
    );

    expect(state, isNull);
  });

  test('reset() clears the state back to no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(testGitHubConnectionNotifierProvider, (_, _) {});
    await container.read(testGitHubConnectionNotifierProvider.future);

    container.read(testGitHubConnectionNotifierProvider.notifier).reset();

    expect(container.read(testGitHubConnectionNotifierProvider).value, isNull);
  });
}
