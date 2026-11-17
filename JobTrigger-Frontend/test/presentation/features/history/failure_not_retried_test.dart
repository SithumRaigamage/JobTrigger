import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/history_filter.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/history/global_history_notifier.dart';
import 'package:job_trigger/presentation/features/history/job_history_notifier.dart';
import 'package:job_trigger/presentation/features/history/job_history_pages_notifier.dart';
import 'package:job_trigger/presentation/features/home/job_tree_notifier.dart';
import '../../../support/fake_jenkins_repository.dart';

// P19-03: with Riverpod's default retry a failed fetch reads as "loading"
// for minutes, so the History screens kept their spinner instead of the
// error and its Retry button. These use a default container (no `retry:`
// override, unlike the other notifier tests) to pin the providers' own
// opt-out.

const _jobUrl = 'https://jenkins.test/job/demo/';

class _UnreachableJenkins extends FakeJenkinsRepository {
  int calls = 0;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async {
    calls++;
    return const Err(NetworkFailure());
  }

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) async {
    calls++;
    return const Err(NetworkFailure());
  }
}

void main() {
  late _UnreachableJenkins repo;
  late ProviderContainer container;

  setUp(() {
    repo = _UnreachableJenkins();
    container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  final cases = <String, Future<Object?> Function(ProviderContainer)>{
    'job tree': (c) => c.read(jobTreeNotifierProvider.future),
    'global history': (c) => c.read(globalHistoryNotifierProvider.future),
    'job history': (c) => c.read(jobHistoryNotifierProvider(_jobUrl).future),
    'job history pages': (c) =>
        c.read(jobHistoryPagesNotifierProvider(_jobUrl).future),
  };

  for (final MapEntry(:key, :value) in cases.entries) {
    test('$key fails at once, once, instead of retrying', () async {
      await expectLater(
        value(container).timeout(const Duration(seconds: 2)),
        throwsA(isA<NetworkFailure>()),
      );
      expect(repo.calls, 1);
    });
  }
}
