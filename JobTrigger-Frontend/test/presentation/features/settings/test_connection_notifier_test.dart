import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/settings/test_connection_notifier.dart';

// `test()` itself calls `testJenkinsConnection()` directly — a top-level
// function that always builds its own internal `Dio` with no seam to
// inject a fake adapter (see `jenkins_client_factory.dart`). This is the
// same shape already accepted as untested elsewhere in this codebase (see
// `tasks/phase-8-github-actions.md`'s P8-04 note on `testGitHubConnection`),
// so only the notifier's own state handling — not covered by that
// reasoning — is exercised here.
void main() {
  test('the initial state has no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(testConnectionNotifierProvider.future);

    expect(state, isNull);
  });

  test('reset() clears the state back to no result', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(testConnectionNotifierProvider, (_, _) {});
    await container.read(testConnectionNotifierProvider.future);

    container.read(testConnectionNotifierProvider.notifier).reset();

    expect(container.read(testConnectionNotifierProvider).value, isNull);
  });
}
