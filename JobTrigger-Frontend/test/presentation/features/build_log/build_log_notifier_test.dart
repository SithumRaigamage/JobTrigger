import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/features/build_log/build_log_notifier.dart';

const _buildUrl = 'https://jenkins.test/job/demo/1/';

/// Serves pre-scripted chunks by call order, recording the `start` offset
/// each call was made with -- lets tests assert the notifier actually
/// advances the offset it was told to use, not just that text accumulates.
class _ScriptedRepository implements JenkinsRepository {
  _ScriptedRepository(this._chunks);

  final List<LogChunk> _chunks;
  final List<int> requestedOffsets = [];
  int _callIndex = 0;

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) async {
    requestedOffsets.add(start);
    final chunk = _chunks[_callIndex];
    _callIndex = (_callIndex + 1).clamp(0, _chunks.length - 1);
    return Ok(chunk);
  }

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() =>
      throw UnimplementedError();

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) =>
      throw UnimplementedError();

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) =>
      throw UnimplementedError();
}

void main() {
  test(
    'the first read starts at offset 0 and stops immediately if hasMoreData is false',
    () async {
      final repo = _ScriptedRepository([
        const LogChunk(
          text: 'build started\n',
          nextOffset: 14,
          hasMoreData: false,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final text = await container.read(
        buildLogNotifierProvider(_buildUrl).future,
      );

      expect(repo.requestedOffsets, [0]);
      expect(text, 'build started\n');
    },
  );

  test(
    'accumulates text and advances the offset across multiple reads',
    () async {
      final repo = _ScriptedRepository([
        const LogChunk(text: 'line 1\n', nextOffset: 7, hasMoreData: true),
        const LogChunk(text: 'line 2\n', nextOffset: 14, hasMoreData: true),
        const LogChunk(text: 'line 3\n', nextOffset: 21, hasMoreData: false),
      ]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Without an active listener, this @riverpod provider auto-disposes
      // once .future resolves -- cancelling the scheduled timer before it
      // ever fires. Keep it alive for the duration of the test.
      container.listen(buildLogNotifierProvider(_buildUrl), (_, _) {});
      await container.read(buildLogNotifierProvider(_buildUrl).future);

      // Wait past the ~1s poll interval twice, to let both remaining chunks
      // arrive.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(repo.requestedOffsets, [0, 7, 14]);
      expect(
        container.read(buildLogNotifierProvider(_buildUrl)).value,
        'line 1\nline 2\nline 3\n',
      );
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  test(
    'stops polling once hasMoreData is false -- no further reads happen',
    () async {
      final repo = _ScriptedRepository([
        const LogChunk(text: 'line 1\n', nextOffset: 7, hasMoreData: true),
        const LogChunk(text: 'line 2\n', nextOffset: 14, hasMoreData: false),
      ]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.listen(buildLogNotifierProvider(_buildUrl), (_, _) {});
      await container.read(buildLogNotifierProvider(_buildUrl).future);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(repo.requestedOffsets, [0, 7]);

      // Wait well past another poll interval -- call count must not grow,
      // since the second chunk said hasMoreData: false.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(repo.requestedOffsets, [0, 7]);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
