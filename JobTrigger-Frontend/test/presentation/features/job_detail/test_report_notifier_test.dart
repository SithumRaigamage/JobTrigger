import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/test_report_notifier.dart';
import '../../../support/fake_jenkins_repository.dart';

const _buildUrl = 'https://jenkins.test/job/demo/1/';

class _FakeRepository extends FakeJenkinsRepository {
  _FakeRepository(this.result);

  final Result<TestReport?, AppFailure> result;
  int fetchTestReportCallCount = 0;

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(
    String buildUrl,
  ) async {
    fetchTestReportCallCount++;
    return result;
  }
}

void main() {
  test('a successful fetch with a published report resolves to it', () async {
    final repo = _FakeRepository(
      const Ok(
        TestReport(
          passCount: 10,
          failCount: 1,
          skipCount: 0,
          failingTests: ['com.example.FooTest.testBar'],
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final report = await container.read(
      testReportNotifierProvider(_buildUrl).future,
    );

    expect(report?.passCount, 10);
    expect(report?.failCount, 1);
    expect(report?.failingTests, ['com.example.FooTest.testBar']);
    expect(repo.fetchTestReportCallCount, 1);
  });

  test(
    'a successful fetch with no published report resolves to null (not an error)',
    () async {
      final repo = _FakeRepository(const Ok(null));
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final report = await container.read(
        testReportNotifierProvider(_buildUrl).future,
      );

      expect(report, isNull);
      expect(
        container.read(testReportNotifierProvider(_buildUrl)).hasError,
        isFalse,
      );
    },
  );

  test(
    'a repository failure maps to AsyncError carrying the AppFailure',
    () async {
      final repo = _FakeRepository(const Err(NotFoundFailure()));
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      // Keep the (autoDispose) provider alive so its settled error state can
      // be observed below -- `.future` itself isn't used here: awaiting it
      // for a family provider that already has a permanent listener attached
      // never resolves in this Riverpod version, so the settled `AsyncError`
      // is polled for directly instead.
      container.listen(testReportNotifierProvider(_buildUrl), (_, _) {});

      final state = await _settled(
        () => container.read(testReportNotifierProvider(_buildUrl)),
      );

      expect(state.error, isA<NotFoundFailure>());
    },
  );
}

/// Polls [read] until it stops reporting `AsyncLoading`, for asserting on an
/// `AsyncNotifier`'s settled state without relying on `.future` (see the
/// test above for why).
Future<AsyncValue<T>> _settled<T>(AsyncValue<T> Function() read) async {
  var state = read();
  for (var i = 0; i < 100 && state.isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
    state = read();
  }
  return state;
}
