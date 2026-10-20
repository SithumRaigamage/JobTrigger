import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/home/folder_contents_notifier.dart';
import 'package:job_trigger/presentation/features/home/multibranch_notifiers.dart';

import '../../../support/fake_jenkins_repository.dart';

const _project = 'https://jenkins.test/job/api/';

class _ScanRepository extends FakeJenkinsRepository {
  _ScanRepository({this.scanResult = const Ok(null)});

  final Result<void, AppFailure> scanResult;

  /// How many indexing-log polls report the scan as still running.
  int runningPolls = 2;
  final logUrls = <String>[];
  int folderFetches = 0;

  @override
  Future<Result<void, AppFailure>> scanMultibranch(String projectUrl) async =>
      scanResult;

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) async {
    logUrls.add(buildUrl);
    final running = runningPolls-- > 0;
    return Ok(LogChunk(text: '', nextOffset: 0, hasMoreData: running));
  }

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async {
    folderFetches++;
    return const Ok([]);
  }
}

ProviderContainer _container(_ScanRepository repository) {
  final container = ProviderContainer(
    overrides: [jenkinsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container
    ..listen(multibranchScanNotifierProvider(_project), (_, _) {})
    ..listen(folderContentsNotifierProvider(_project), (_, _) {})
    // Auto-disposed: without a listener it resets between reads.
    ..listen(currentToastProvider, (_, _) {});
  return container;
}

void main() {
  testWidgets('polls the indexing log until done, then refreshes the project', (
    tester,
  ) async {
    final repository = _ScanRepository();
    final container = _container(repository);
    await tester.pump();
    expect(repository.folderFetches, 1);

    await container
        .read(multibranchScanNotifierProvider(_project).notifier)
        .scan();
    expect(container.read(multibranchScanNotifierProvider(_project)), isTrue);
    expect(container.read(currentToastProvider)?.title, 'Scan started');

    // Two "still running" polls, then one "finished".
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.pump();

    expect(repository.logUrls, List.filled(3, '${_project}indexing/'));
    expect(container.read(multibranchScanNotifierProvider(_project)), isFalse);
    expect(repository.folderFetches, 2, reason: 'project refreshed');
    expect(container.read(currentToastProvider)?.title, 'Scan finished');
    // Let the toast's auto-dismiss timer run out before teardown.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a refused scan stops and reports the failure', (tester) async {
    final repository = _ScanRepository(
      scanResult: const Err(PermissionFailure()),
    );
    final container = _container(repository);

    await container
        .read(multibranchScanNotifierProvider(_project).notifier)
        .scan();

    expect(container.read(multibranchScanNotifierProvider(_project)), isFalse);
    final toast = container.read(currentToastProvider);
    expect(toast?.type, ToastType.error);
    expect(toast?.message, const PermissionFailure().message);
    await tester.pump(const Duration(seconds: 5));
    expect(repository.logUrls, isEmpty, reason: 'no polling after a refusal');
  });
}
