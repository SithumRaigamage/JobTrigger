import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/network/sonarqube_client_factory.dart';

part 'test_sonarqube_connection_notifier.g.dart';

/// "Test connection" (`US-SQ-CRED-04`) state — mirrors
/// `TestGitHubConnectionNotifier`'s shape: `state.value` is `null` before
/// the first test (idle) and `true` after a successful one. SonarQube's
/// `/api/authentication/validate` has nothing equivalent to GitHub's
/// `/user` to report back on success (no username), so `bool?` replaces
/// GitHub's `String?` as the idle/success sentinel — `AsyncValue<void>`
/// would have made "never tested" and "tested successfully" both render
/// as `AsyncData(null)`, indistinguishable to the UI.
@riverpod
class TestSonarQubeConnectionNotifier extends _$TestSonarQubeConnectionNotifier {
  @override
  FutureOr<bool?> build() => null;

  Future<void> test({required String baseUrl, required String token}) async {
    state = const AsyncLoading();
    final result = await testSonarQubeConnection(baseUrl: baseUrl, token: token);
    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final error) => AsyncError(error, StackTrace.current),
    };
  }

  void reset() => state = const AsyncData(null);
}
