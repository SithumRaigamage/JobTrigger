import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';

JenkinsBuild _b(int n, String? result, {bool building = false}) => JenkinsBuild(
  number: n,
  url: 'u$n',
  result: result,
  building: building,
  timestamp: 0,
  duration: 252000,
);

const _build7 = BuildWatch(
  serverId: 's',
  jobUrl: 'https://ci/job/api/',
  jobLabel: 'api',
  buildNumber: 7,
);
const _job = BuildWatch(
  serverId: 's',
  jobUrl: 'https://ci/job/api/',
  jobLabel: 'api',
  lastNotified: 7,
);

void main() {
  group('a one-build watch (US-JX-10)', () {
    test('keeps waiting while the build runs', () {
      final outcome = decideWatch(_build7, [_b(7, null, building: true)]);
      expect(outcome.keep, same(_build7));
      expect(outcome.notify, isNull);
    });

    test('notifies once when it finishes, then is dropped', () {
      final outcome = decideWatch(_build7, [
        _b(8, null, building: true),
        _b(7, 'FAILURE'),
      ]);
      expect(outcome.keep, isNull);
      expect(outcome.notify!.title, '❌ api #7 failed');
      expect(outcome.notify!.body, 'Took 4m 12s');
      expect(outcome.notify!.jobUrl, 'https://ci/job/api/');
    });

    test('is dropped when the build is older than anything returned', () {
      expect(
        decideWatch(_build7, [_b(30, 'SUCCESS'), _b(20, 'SUCCESS')]).keep,
        isNull,
      );
    });

    test('is kept while the build has not appeared yet (still queued)', () {
      expect(decideWatch(_build7, [_b(6, 'SUCCESS')]).keep, same(_build7));
    });
  });

  group('a job watch', () {
    test('notifies for the newest finished build only, then advances', () {
      final outcome = decideWatch(_job, [
        _b(10, null, building: true),
        _b(9, 'SUCCESS'),
        _b(8, 'FAILURE'),
      ]);
      expect(outcome.notify!.title, '✅ api #9 succeeded');
      expect(outcome.keep!.lastNotified, 9);
    });

    test('stays quiet until there is a newer finished build', () {
      final outcome = decideWatch(_job, [
        _b(8, null, building: true),
        _b(7, 'SUCCESS'),
      ]);
      expect(outcome.notify, isNull);
      expect(outcome.keep, same(_job));
    });
  });

  test('the notification id is stable per build', () {
    expect(
      notificationFor(_job, _b(9, 'SUCCESS')).id,
      notificationFor(_build7, _b(9, 'ABORTED')).id,
    );
  });

  test('json round-trip', () {
    final back = BuildWatch.fromJson(_build7.toJson());
    expect(back.key, _build7.key);
    expect(back.buildNumber, 7);
  });
}
