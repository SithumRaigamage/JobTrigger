import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/biometric_service.dart';
import 'package:job_trigger/core/platform/home_widget_bridge.dart';
import 'package:job_trigger/core/platform/notification_service.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credentials_repository.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home/pinned_jobs_notifier.dart';
import 'package:job_trigger/presentation/features/home/views_notifier.dart';
import 'package:job_trigger/presentation/features/home_widget/home_widget_sync.dart';
import 'package:job_trigger/presentation/features/notifications/background_watch.dart';
import 'package:job_trigger/presentation/features/notifications/build_watch_notifier.dart';
import 'package:job_trigger/presentation/features/settings/github_credential_form_notifier.dart';
import 'package:job_trigger/presentation/features/settings/server_form_notifier.dart';
import 'package:job_trigger/presentation/features/settings/sonarqube_credential_form_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/plan_gate.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_biometric_service.dart';
import '../../../../support/fake_home_widget_bridge.dart';
import '../../../../support/fake_jenkins_repository.dart';
import '../../../../support/plan_gates.dart';

/// P20-25: every gate, allowed and blocked, at the notifier. With billing
/// on and on Free the blocked result carries the paywall reason the UI
/// opens (`openPaywall(context, reason)`); on Pro, or with billing off, it
/// is allowed.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('pinned jobs', () {
    ProviderContainer make(PlanGate gate, {int pinned = 0}) {
      final c = ProviderContainer(
        overrides: [
          gateOverride(gate),
          activeServerNotifierProvider.overrideWith(_ServerA.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(pinnedJobsNotifierProvider, (_, _) {});
      return c;
    }

    Future<ProviderContainer> withPins(PlanGate gate, int count) async {
      final c = make(gate);
      final notifier = c.read(pinnedJobsNotifierProvider.notifier);
      for (var i = 0; i < count; i++) {
        await notifier.toggle(
          JenkinsJob(name: 'j$i', url: 'https://a.test/job/j$i/'),
        );
      }
      return c;
    }

    test('Free: the 3rd pin is allowed, the 4th opens maxPinnedJobs', () async {
      final c = await withPins(freeGate, 2);
      final notifier = c.read(pinnedJobsNotifierProvider.notifier);
      expect(notifier.pinBlockedReason('https://a.test/job/new/'), isNull);
      await notifier.toggle(
        const JenkinsJob(name: 'j2', url: 'https://a.test/job/j2/'),
      );
      expect(
        notifier.pinBlockedReason('https://a.test/job/new/'),
        'maxPinnedJobs',
      );
    });

    test(
      'Free: unpinning, and pins already pinned, are never blocked',
      () async {
        final c = await withPins(freeGate, 3);
        final notifier = c.read(pinnedJobsNotifierProvider.notifier);
        expect(notifier.pinBlockedReason('https://a.test/job/j0/'), isNull);
      },
    );

    test('Pro and billing off: no pin limit', () async {
      for (final gate in [proGate, PlanGate.open]) {
        final c = await withPins(gate, 6);
        expect(
          c
              .read(pinnedJobsNotifierProvider.notifier)
              .pinBlockedReason('https://a.test/job/new/'),
          isNull,
        );
      }
    });
  });

  group('build watches', () {
    const job = JenkinsJob(
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

    Future<(ProviderContainer, _Scheduler)> make(PlanGate gate) async {
      final scheduler = _Scheduler();
      final c = ProviderContainer(
        overrides: [
          gateOverride(gate),
          activeServerNotifierProvider.overrideWith(_ServerA.new),
          notificationServiceProvider.overrideWithValue(_Notifications()),
          backgroundWatchSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(c.dispose);
      c.read(buildWatchNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      return (c, scheduler);
    }

    test('Free: blocked with backgroundWatch, and nothing is stored', () async {
      final (c, scheduler) = await make(freeGate);
      final notifier = c.read(buildWatchNotifierProvider.notifier);

      expect(notifier.blockedReason, 'backgroundWatch');
      expect(
        await notifier.watchBuild(job, job.lastBuild!),
        WatchResult.requiresPro,
      );
      expect(await notifier.watchJob(job), WatchResult.requiresPro);
      expect(c.read(buildWatchNotifierProvider), isEmpty);
      expect(scheduler.synced.where((s) => s), isEmpty);
    });

    test('Pro: allowed, and scheduled', () async {
      final (c, scheduler) = await make(proGate);
      final notifier = c.read(buildWatchNotifierProvider.notifier);

      expect(notifier.blockedReason, isNull);
      expect(await notifier.watchBuild(job, job.lastBuild!), WatchResult.added);
      expect(scheduler.synced.last, isTrue);
    });

    test(
      'after a downgrade, stored watches stay but are not scheduled',
      () async {
        // Added while Pro...
        final pro = await make(proGate);
        await pro.$1
            .read(buildWatchNotifierProvider.notifier)
            .watchBuild(job, job.lastBuild!);
        // ...then the same store is read on Free.
        final (c, scheduler) = await make(freeGate);
        expect(c.read(buildWatchNotifierProvider), hasLength(1));
        expect(scheduler.synced.last, isFalse);
      },
    );
  });

  group('home widget', () {
    Future<FakeHomeWidgetBridge> run(PlanGate gate) async {
      final bridge = FakeHomeWidgetBridge();
      final c = ProviderContainer(
        overrides: [
          gateOverride(gate),
          biometricServiceProvider.overrideWithValue(FakeBiometricService()),
          homeWidgetBridgeProvider.overrideWithValue(bridge),
          pinnedJobsNotifierProvider.overrideWith(_Pins.new),
          jenkinsRepositoryProvider.overrideWithValue(_Repo()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(authNotifierProvider.future);
      c.listen(homeWidgetSyncProvider, (_, _) {});
      await c
          .read(authNotifierProvider.notifier)
          .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt');
      await pumpEventQueue();
      return bridge;
    }

    test('Free: the widget gets an upgrade snapshot, never the jobs', () async {
      final bridge = await run(freeGate);
      expect(bridge.written, isNotEmpty);
      expect(bridge.written.every((s) => s.upgradeRequired), isTrue);
      expect(bridge.written.every((s) => s.jobs.isEmpty), isTrue);
      expect(bridge.written.last.toJson()['upgradeRequired'], isTrue);
    });

    test('Pro and billing off: the pinned job reaches the widget', () async {
      for (final gate in [proGate, PlanGate.open]) {
        final bridge = await run(gate);
        final last = bridge.written.last;
        expect(last.upgradeRequired, isFalse);
        expect(last.jobs.single.label, 'api');
        expect(last.toJson().containsKey('upgradeRequired'), isFalse);
      }
    });
  });

  group('insights (views)', () {
    test(
      'Free: blocked with insights, and the saved view is ignored',
      () async {
        SharedPreferences.setMockInitialValues({
          'selected_view_a': 'https://a.test/view/x/',
        });
        final c = ProviderContainer(
          overrides: [
            gateOverride(freeGate),
            activeServerNotifierProvider.overrideWith(_ServerA.new),
          ],
        );
        addTearDown(c.dispose);
        c.listen(selectedViewNotifierProvider, (_, _) {});
        await pumpEventQueue();
        expect(
          c.read(selectedViewNotifierProvider.notifier).blockedReason,
          'insights',
        );
        expect(c.read(selectedViewNotifierProvider), isNull);
      },
    );

    test('Pro: allowed, and the saved view applies', () async {
      SharedPreferences.setMockInitialValues({
        'selected_view_a': 'https://a.test/view/x/',
      });
      final c = ProviderContainer(
        overrides: [
          gateOverride(proGate),
          activeServerNotifierProvider.overrideWith(_ServerA.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(selectedViewNotifierProvider, (_, _) {});
      await pumpEventQueue();
      expect(
        c.read(selectedViewNotifierProvider.notifier).blockedReason,
        isNull,
      );
      expect(c.read(selectedViewNotifierProvider), 'https://a.test/view/x/');
    });
  });

  group('switching tool', () {
    Future<String?> blocked(
      PlanGate gate,
      CiTool tool, {
      List<JenkinsServer> jenkins = const [],
      bool github = false,
    }) {
      final c = ProviderContainer(
        overrides: [
          gateOverride(gate),
          ...savedCredentials(
            jenkins: jenkins,
            github: [if (github) gitHubCredentialNamed('g')],
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(activeToolNotifierProvider, (_, _) {});
      return c.read(activeToolNotifierProvider.notifier).blockedReason(tool);
    }

    test('Free: another tool than the one in use opens multiTool', () async {
      expect(
        await blocked(
          freeGate,
          CiTool.githubActions,
          jenkins: [jenkinsServerNamed('a')],
        ),
        'multiTool',
      );
    });

    test('Free: the tool in use, and the first tool, are allowed', () async {
      expect(
        await blocked(
          freeGate,
          CiTool.jenkins,
          jenkins: [jenkinsServerNamed('a')],
        ),
        isNull,
      );
      expect(await blocked(freeGate, CiTool.sonarqube), isNull);
    });

    test('Free: a tool with its own saved server stays usable', () async {
      // After a downgrade from multi-tool the user may have two.
      expect(
        await blocked(
          freeGate,
          CiTool.githubActions,
          jenkins: [jenkinsServerNamed('a')],
          github: true,
        ),
        isNull,
      );
    });

    test('Pro and billing off: any tool', () async {
      for (final gate in [proGate, PlanGate.open]) {
        expect(
          await blocked(
            gate,
            CiTool.githubActions,
            jenkins: [jenkinsServerNamed('a')],
          ),
          isNull,
        );
      }
    });
  });

  group('adding a server or account', () {
    test('Free: a second server is refused with maxCredentialsTotal, across '
        'tools', () async {
      final c = ProviderContainer(
        overrides: [
          gateOverride(freeGate),
          ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
        ],
      );
      addTearDown(c.dispose);
      final ref = c.read(_refProbe);
      final github = await addCredentialBlock(ref, CiTool.githubActions);
      expect(github?.limit, 'maxCredentialsTotal');
      expect(
        github?.message,
        'Your plan allows 1 saved server. Upgrade to Pro to add more.',
      );
    });

    test('Free: the first server is allowed', () async {
      final c = ProviderContainer(
        overrides: [gateOverride(freeGate), ...savedCredentials()],
      );
      addTearDown(c.dispose);
      expect(
        await addCredentialBlock(c.read(_refProbe), CiTool.jenkins),
        isNull,
      );
    });

    test('Pro and billing off: never refused', () async {
      for (final gate in [proGate, PlanGate.open]) {
        final c = ProviderContainer(
          overrides: [
            gateOverride(gate),
            ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
          ],
        );
        addTearDown(c.dispose);
        expect(
          await addCredentialBlock(c.read(_refProbe), CiTool.jenkins),
          isNull,
        );
      }
    });

    test('Jenkins form: a blocked add never reaches the backend; an edit '
        'does', () async {
      final repository = _JenkinsRepo();
      final c = ProviderContainer(
        overrides: [
          gateOverride(freeGate),
          ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
          credentialsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);
      c.listen(serverFormNotifierProvider, (_, _) {});
      final form = c.read(serverFormNotifierProvider.notifier);

      await form.save(
        serverName: 'b',
        jenkinsURL: 'https://b.test',
        username: 'u',
        secret: 's',
        isDefault: false,
      );
      final error = c.read(serverFormNotifierProvider).error;
      expect(error, isA<PlanLimitFailure>());
      expect((error! as PlanLimitFailure).limit, 'maxCredentialsTotal');
      expect(repository.adds, 0);

      await form.save(
        id: 'a',
        serverName: 'a',
        jenkinsURL: 'https://a.test',
        username: 'u',
        secret: 's',
        isDefault: false,
      );
      expect(repository.updates, 1);
    });

    test(
      'GitHub and SonarQube forms refuse a blocked add the same way',
      () async {
        final c = ProviderContainer(
          overrides: [
            gateOverride(freeGate),
            ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
            gitHubCredentialsRepositoryProvider.overrideWithValue(
              _NeverCalledGitHub(),
            ),
            sonarQubeCredentialsRepositoryProvider.overrideWithValue(
              _NeverCalledSonar(),
            ),
          ],
        );
        addTearDown(c.dispose);
        c.listen(gitHubCredentialFormNotifierProvider, (_, _) {});
        c.listen(sonarQubeCredentialFormNotifierProvider, (_, _) {});

        await c
            .read(gitHubCredentialFormNotifierProvider.notifier)
            .save(label: 'g', secret: 't', isDefault: false);
        await c
            .read(sonarQubeCredentialFormNotifierProvider.notifier)
            .save(
              label: 's',
              baseUrl: 'https://sonar.test',
              secret: 't',
              isDefault: false,
            );
        expect(
          c.read(gitHubCredentialFormNotifierProvider).error,
          isA<PlanLimitFailure>(),
        );
        expect(
          c.read(sonarQubeCredentialFormNotifierProvider).error,
          isA<PlanLimitFailure>(),
        );
      },
    );
  });
}

/// A `Ref` for calling the helpers that take one, from a test.
final _refProbe = Provider<Ref>((ref) => ref);

class _ServerA extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => jenkinsServerNamed('a');
}

class _Pins extends PinnedJobsNotifier {
  @override
  List<PinnedJob> build() => const [
    PinnedJob(url: 'https://ci/job/api/', label: 'api'),
  ];
}

class _Repo extends FakeJenkinsRepository {
  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobStatus(String jobUrl) async =>
      Ok(JenkinsJob(name: 'api', url: jobUrl, color: 'red'));
}

class _Notifications implements NotificationService {
  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> showSubscriptionAlert({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> show(BuildNotification notification) async {}
}

class _Scheduler implements BackgroundWatchScheduler {
  @override
  bool get isSupported => true;

  final synced = <bool>[];

  @override
  Future<void> sync({
    required bool hasWatches,
    bool hasGateWatches = false,
  }) async => synced.add(hasWatches);
}

class _JenkinsRepo implements CredentialsRepository {
  int adds = 0;
  int updates = 0;

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    adds++;
    return Ok(jenkinsServerNamed('new'));
  }

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    updates++;
    return Ok(jenkinsServerNamed(id));
  }

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      Ok([jenkinsServerNamed('a')]);

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

class _NeverCalledGitHub implements GitHubCredentialsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('the backend must not be called');
}

class _NeverCalledSonar implements SonarQubeCredentialsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('the backend must not be called');
}
