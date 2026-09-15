import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/network/jenkins_client_factory.dart';

part 'test_connection_notifier.g.dart';

/// "Test connection" (P3-08) state — separate from `ServerFormNotifier`
/// since a user can test a candidate server's connection independently of
/// (and repeatedly before) actually saving it. `state.value` is `null`
/// before the first test; otherwise the job count on success, with the
/// failure surfaced as `AsyncError` like everywhere else.
@riverpod
class TestConnectionNotifier extends _$TestConnectionNotifier {
  @override
  FutureOr<int?> build() => null;

  Future<void> test({
    required String jenkinsURL,
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await testJenkinsConnection(
      jenkinsURL: jenkinsURL,
      username: username,
      password: password,
    );
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final error) => AsyncError(error, StackTrace.current),
    };
  }

  void reset() => state = const AsyncData(null);
}
