import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/cache/build_watch_store.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/history_filter.dart';
import 'package:job_trigger/presentation/features/notifications/watch_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

class _Repo extends FakeJenkinsRepository {
  _Repo(this.history);

  final Result<List<JenkinsBuild>, AppFailure> history;
  int calls = 0;

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) async {
    calls++;
    return history;
  }
}

const _finished = JenkinsBuild(
  number: 7,
  url: 'https://ci/job/api/7/',
  result: 'SUCCESS',
  building: false,
  timestamp: 0,
  duration: 1000,
);

BuildWatch _watch(String job, {String server = 's1'}) => BuildWatch(
  serverId: server,
  jobUrl: 'https://ci/job/$job/',
  jobLabel: job,
  buildNumber: 7,
);

void main() {
  late BuildWatchStore store;
  late List<BuildNotification> shown;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = BuildWatchStore();
    shown = [];
  });

  Future<List<BuildWatch>> run(RepositoryForServer repositoryFor) =>
      runWatchCheck(
        store: store,
        repositoryFor: repositoryFor,
        notify: (notification) async => shown.add(notification),
      );

  test('notifies for a finished build and drops its watch', () async {
    await store.save([_watch('api')]);
    final remaining = await run((_) async => _Repo(const Ok([_finished])));
    expect(shown.single.title, 'api #7 succeeded');
    expect(remaining, isEmpty);
    expect(await store.load(), isEmpty);
  });

  test('drops watches whose server credentials are gone', () async {
    await store.save([_watch('api')]);
    final remaining = await run((_) async => null);
    expect(shown, isEmpty);
    expect(remaining, isEmpty);
  });

  test('keeps watches when the server list is unreachable', () async {
    await store.save([_watch('api')]);
    final remaining = await run((_) async => throw const NetworkFailure());
    expect(shown, isEmpty);
    expect(remaining.single.jobUrl, 'https://ci/job/api/');
  });

  test('keeps watches when Jenkins fails transiently', () async {
    await store.save([_watch('api')]);
    final remaining = await run(
      (_) async => _Repo(const Err(NetworkFailure())),
    );
    expect(remaining, hasLength(1));
    expect(await store.load(), hasLength(1));
  });

  test('resolves each server once per pass', () async {
    await store.save([_watch('api'), _watch('web')]);
    var lookups = 0;
    final repo = _Repo(const Ok([_finished]));
    await run((_) async {
      lookups++;
      return repo;
    });
    expect(lookups, 1);
    expect(repo.calls, 2);
    expect(shown, hasLength(2));
  });

  group('changes during a pass (AUD-49)', () {
    test('a watch added mid-pass survives', () async {
      await store.save([_watch('api')]);
      final remaining = await run((_) async {
        // The user taps "Notify me" while this pass is on the network.
        await store.save([...await store.load(), _watch('web')]);
        return _Repo(const Ok([]));
      });
      expect(remaining.map((w) => w.jobLabel), ['api', 'web']);
      expect((await store.load()).map((w) => w.jobLabel), ['api', 'web']);
    });

    test('a watch removed mid-pass stays removed', () async {
      await store.save([_watch('api'), _watch('web')]);
      final remaining = await run((_) async {
        await store.save([_watch('web')]); // Unwatch "api".
        return _Repo(const Ok([])); // Neither build finished: both "kept".
      });
      expect(remaining.map((w) => w.jobLabel), ['web']);
    });

    test('the final merge goes through the given serializer', () async {
      await store.save([_watch('api')]);
      var serialized = 0;
      await runWatchCheck(
        store: store,
        repositoryFor: (_) async => _Repo(const Ok([_finished])),
        notify: (_) async {},
        serialize: (write) {
          serialized++;
          return write();
        },
      );
      expect(serialized, 1);
    });
  });
}
