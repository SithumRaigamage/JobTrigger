import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/notification_service.dart';
import 'package:job_trigger/data/cache/build_watch_store.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/notifications/background_watch.dart';
import 'package:job_trigger/presentation/features/notifications/build_watch_notifier.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 's1',
    serverName: 's1',
    jenkinsURL: 'https://ci',
    username: 'u',
    secret: 's',
  );
}

class _NoServer extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => null;
}

class _Notifications implements NotificationService {
  _Notifications({this.granted = true});

  final bool granted;

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> show(BuildNotification notification) async {}
}

class _Scheduler implements BackgroundWatchScheduler {
  final synced = <bool>[];

  @override
  Future<void> sync({required bool hasWatches}) async => synced.add(hasWatches);
}

const _job = JenkinsJob(
  name: 'api',
  url: 'https://ci/job/api/',
  lastBuild: JenkinsBuild(
    number: 9,
    url: 'https://ci/job/api/9/',
    building: true,
    timestamp: 0,
    duration: 0,
  ),
);

void main() {
  late _Scheduler scheduler;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    scheduler = _Scheduler();
  });

  Future<ProviderContainer> container({
    bool granted = true,
    bool hasServer = true,
  }) async {
    final c = ProviderContainer(
      overrides: [
        activeServerNotifierProvider.overrideWith(
          hasServer ? _Server.new : _NoServer.new,
        ),
        notificationServiceProvider.overrideWithValue(
          _Notifications(granted: granted),
        ),
        backgroundWatchSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    addTearDown(c.dispose);
    c.read(buildWatchNotifierProvider);
    await Future<void>.delayed(Duration.zero); // Initial load.
    return c;
  }

  test(
    'watching a build persists it and schedules the background check',
    () async {
      final c = await container();
      final notifier = c.read(buildWatchNotifierProvider.notifier);
      final result = await notifier.watchBuild(_job, _job.lastBuild!);

      expect(result, WatchResult.added);
      expect(notifier.isWatching(jobUrl: _job.url, buildNumber: 9), isTrue);
      expect((await BuildWatchStore().load()).single.buildNumber, 9);
      expect(scheduler.synced.last, isTrue);
    },
  );

  test('watching a job starts after its current last build', () async {
    final c = await container();
    await c.read(buildWatchNotifierProvider.notifier).watchJob(_job);
    final watch = c.read(buildWatchNotifierProvider).single;
    expect(watch.buildNumber, isNull);
    expect(watch.lastNotified, 9);
  });

  test('watching the same build twice keeps one watch', () async {
    final c = await container();
    final notifier = c.read(buildWatchNotifierProvider.notifier);
    await notifier.watchBuild(_job, _job.lastBuild!);
    await notifier.watchBuild(_job, _job.lastBuild!);
    expect(c.read(buildWatchNotifierProvider), hasLength(1));
  });

  test('a denied permission adds nothing', () async {
    final c = await container(granted: false);
    final result = await c
        .read(buildWatchNotifierProvider.notifier)
        .watchBuild(_job, _job.lastBuild!);
    expect(result, WatchResult.permissionDenied);
    expect(c.read(buildWatchNotifierProvider), isEmpty);
    expect(await BuildWatchStore().load(), isEmpty);
  });

  test('without an active server nothing is added', () async {
    final c = await container(hasServer: false);
    final result = await c
        .read(buildWatchNotifierProvider.notifier)
        .watchJob(_job);
    expect(result, WatchResult.noServer);
  });

  test('unwatching the last watch cancels the background check', () async {
    final c = await container();
    final notifier = c.read(buildWatchNotifierProvider.notifier);
    await notifier.watchBuild(_job, _job.lastBuild!);
    await notifier.unwatch(c.read(buildWatchNotifierProvider).single);
    expect(c.read(buildWatchNotifierProvider), isEmpty);
    expect(await BuildWatchStore().load(), isEmpty);
    expect(scheduler.synced.last, isFalse);
  });

  test('restores saved watches on start', () async {
    await BuildWatchStore().save([
      const BuildWatch(
        serverId: 's1',
        jobUrl: 'https://ci/job/api/',
        jobLabel: 'api',
        buildNumber: 3,
      ),
    ]);
    final c = await container();
    expect(c.read(buildWatchNotifierProvider).single.buildNumber, 3);
  });
}
