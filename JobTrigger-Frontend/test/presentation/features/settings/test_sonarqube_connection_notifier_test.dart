import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/settings/test_sonarqube_connection_notifier.dart';

// `test()` itself calls `testSonarQubeConnection()` directly -- a top-level
// function that always builds its own internal `Dio` with no seam to
// inject a fake adapter (see `sonarqube_client_factory.dart`, and the same
// already-accepted shape for `testJenkinsConnection`/`testGitHubConnection`).
// Only the notifier's own state handling -- not covered by that reasoning
// -- is exercised here.
void main() {
  test('the initial state has no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      testSonarQubeConnectionNotifierProvider.future,
    );

    expect(state, isNull);
  });

  test('reset() clears the state back to no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(testSonarQubeConnectionNotifierProvider, (_, _) {});
    await container.read(testSonarQubeConnectionNotifierProvider.future);

    container.read(testSonarQubeConnectionNotifierProvider.notifier).reset();

    expect(
      container.read(testSonarQubeConnectionNotifierProvider).value,
      isNull,
    );
  });
}
