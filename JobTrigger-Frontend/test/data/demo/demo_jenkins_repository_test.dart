import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/demo/demo_jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';

const _main = 'https://jenkins.demo.invalid/job/demo-app/job/main/';

/// E2 (PE-10, PE-13): the demo's Jenkins answers from memory, and only
/// "Build now" on `demo-app/main` plays a scripted run.
void main() {
  late DateTime now;
  late DemoJenkinsRepository repo;

  setUp(() {
    now = DateTime(2026, 11, 14, 12);
    repo = DemoJenkinsRepository(clock: () => now);
  });

  T ok<T>(Result<T, AppFailure> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final error) => fail('expected Ok, got $error'),
  };

  test('the root lists a multibranch project, a folder and a job', () async {
    final root = ok(await repo.fetchFolder(null));
    expect(root.map((j) => j.name), ['demo-app', 'platform', 'docs-site']);
    expect(root.first.isMultibranch, isTrue);
    expect(root[1].isFolder, isTrue);
  });

  test('a folder lists its children and an unknown one is not found', () async {
    final kids = ok(await repo.fetchFolder(root('platform')));
    expect(kids.map((j) => j.name), ['deploy-staging', 'nightly-tests']);
    expect(
      await repo.fetchFolder('https://jenkins.demo.invalid/job/nope/'),
      isA<Err<List<JenkinsJob>, AppFailure>>(),
    );
  });

  test('the failed build has a readable log, stages and test report', () async {
    const url =
        'https://jenkins.demo.invalid/job/demo-app/job/feature-login/7/';
    final build = ok(await repo.fetchBuildDetail(url));
    expect(build.result, 'FAILURE');
    final log = ok(await repo.streamBuildLog(url));
    expect(log.text, contains('rejects an empty password'));
    expect(log.hasMoreData, isFalse);
    expect(
      ok(await repo.fetchPipelineStages(url))!.any((s) => s.isFailed),
      isTrue,
    );
    expect(ok(await repo.fetchTestReport(url))!.failCount, 2);
  });

  test('a running build is sample data too', () async {
    const url =
        'https://jenkins.demo.invalid/job/platform/job/deploy-staging/118/';
    expect(ok(await repo.fetchBuildDetail(url)).building, isTrue);
    expect(ok(await repo.streamBuildLog(url)).hasMoreData, isTrue);
  });

  group('scripted "Build now" on demo-app/main', () {
    test(
      'queues, runs through its stages, streams the log, succeeds',
      () async {
        final queueUrl = ok(
          await repo.triggerBuild(_main, isParameterized: false),
        )!;
        expect(ok(await repo.fetchQueue()), hasLength(1));
        expect(ok(await repo.fetchQueueItem(queueUrl)).isResolved, isFalse);

        // Out of the queue after two seconds.
        now = now.add(const Duration(seconds: 3));
        final item = ok(await repo.fetchQueueItem(queueUrl));
        final buildUrl = item.executable!.url;
        expect(item.executable!.number, 42);
        expect(ok(await repo.fetchQueue()), isEmpty);
        expect(ok(await repo.fetchBuildDetail(buildUrl)).building, isTrue);
        final early = ok(await repo.streamBuildLog(buildUrl));
        expect(early.hasMoreData, isTrue);
        expect(early.text, contains('Started by user demo'));
        expect(early.text, isNot(contains('Finished')));

        // Mid-run: one stage in progress, the log has grown, and the next
        // read resumes from the offset it was given.
        now = now.add(const Duration(seconds: 8));
        final stages = ok(await repo.fetchPipelineStages(buildUrl))!;
        expect(stages.map((s) => s.status), contains('IN_PROGRESS'));
        final more = ok(
          await repo.streamBuildLog(buildUrl, start: early.nextOffset),
        );
        expect(more.text, isNotEmpty);
        expect(early.text + more.text, contains('npm test'));

        // About twenty seconds in total: done.
        now = now.add(const Duration(seconds: 12));
        final done = ok(await repo.fetchBuildDetail(buildUrl));
        expect(done.building, isFalse);
        expect(done.result, 'SUCCESS');
        final last = ok(await repo.streamBuildLog(buildUrl));
        expect(last.hasMoreData, isFalse);
        expect(last.text, contains('Finished: SUCCESS'));
        expect(
          ok(await repo.fetchPipelineStages(buildUrl))!.map((s) => s.status),
          everyElement('SUCCESS'),
        );
        final job = ok(await repo.fetchJobDetail(_main));
        expect(job.lastBuild!.number, 42);
      },
    );

    test('a second tap while it runs does not start another', () async {
      final first = ok(await repo.triggerBuild(_main, isParameterized: false));
      now = now.add(const Duration(seconds: 5));
      final second = ok(await repo.triggerBuild(_main, isParameterized: false));
      expect(second, first);
    });

    test('a fresh repository starts over', () async {
      await repo.triggerBuild(_main, isParameterized: false);
      final fresh = DemoJenkinsRepository(clock: () => now);
      expect(ok(await fresh.fetchQueue()), isEmpty);
      expect(ok(await fresh.fetchJobDetail(_main)).lastBuild!.number, 41);
    });
  });

  group('every other write is not available in demo', () {
    Matcher unavailable<T>() => isA<Err<T, AppFailure>>().having(
      (e) => e.error,
      'error',
      isA<DemoUnavailableFailure>(),
    );

    test('build now on another job', () async {
      expect(
        await repo.triggerBuild(
          'https://jenkins.demo.invalid/job/docs-site/',
          isParameterized: false,
        ),
        unavailable<String?>(),
      );
    });

    test('cancel, queue cancel, toggles, scan, input', () async {
      expect(await repo.cancelBuild('x/1/'), unavailable<void>());
      expect(await repo.cancelQueueItem(1), unavailable<void>());
      expect(await repo.toggleKeepLog('x/1/'), unavailable<void>());
      expect(await repo.setBuildDescription('x/1/', 'd'), unavailable<void>());
      expect(
        await repo.setJobEnabled('x/', enabled: false),
        unavailable<void>(),
      );
      expect(await repo.scanMultibranch('x/'), unavailable<void>());
      expect(
        await repo.submitInput(buildUrl: 'x/1/', inputId: 'i', proceed: true),
        unavailable<void>(),
      );
      expect(DemoUnavailableFailure().message, 'Not available in demo.');
    });
  });
}

String root(String name) => 'https://jenkins.demo.invalid/job/$name/';
