import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/network/github_client_factory.dart';

part 'test_github_connection_notifier.g.dart';

/// "Test connection" (`US-GH-CRED-04`) state — mirrors
/// `TestConnectionNotifier`'s shape exactly. `state.value` is `null`
/// before the first test; otherwise the authenticated username on
/// success (unlike Jenkins' job count — GitHub's `/user` has no
/// equivalent count to show).
@riverpod
class TestGitHubConnectionNotifier extends _$TestGitHubConnectionNotifier {
  @override
  FutureOr<String?> build() => null;

  Future<void> test({required String token}) async {
    state = const AsyncLoading();
    final result = await testGitHubConnection(token: token);
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final error) => AsyncError(error, StackTrace.current),
    };
  }

  void reset() => state = const AsyncData(null);
}
