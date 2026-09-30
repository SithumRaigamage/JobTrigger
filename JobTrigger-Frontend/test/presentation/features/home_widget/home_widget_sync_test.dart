import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/home_widget_bridge.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/widget/widget_snapshot.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home/pinned_jobs_notifier.dart';
import 'package:job_trigger/presentation/features/home_widget/home_widget_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_home_widget_bridge.dart';
import '../../../support/fake_jenkins_repository.dart';

class _Pins extends PinnedJobsNotifier {
  @override
  List<PinnedJob> build() => const [
    PinnedJob(url: 'https://ci/job/api/', label: 'api'),
  ];
}

class _Repo extends FakeJenkinsRepository {
  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      Ok(JenkinsJob(name: 'api', url: jobUrl, color: 'red'));
}

void main() {
  late FakeHomeWidgetBridge bridge;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    bridge = FakeHomeWidgetBridge();
  });

  Future<ProviderContainer> container() async {
    final c = ProviderContainer(
      overrides: [
        homeWidgetBridgeProvider.overrideWithValue(bridge),
        pinnedJobsNotifierProvider.overrideWith(_Pins.new),
        jenkinsRepositoryProvider.overrideWithValue(_Repo()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authNotifierProvider.future);
    c.listen(homeWidgetSyncProvider, (_, _) {});
    return c;
  }

  test('signed out, it leaves the pins (and the server) alone', () async {
    await container();
    await Future<void>.delayed(Duration.zero);
    expect(bridge.written, isEmpty);
  });

  test(
    'signed in, a refreshed pin status reaches the widget (US-JX-23)',
    () async {
      final c = await container();
      await c
          .read(authNotifierProvider.notifier)
          .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt');
      await c.read(pinnedJobStatusProvider('https://ci/job/api/').future);
      await Future<void>.delayed(Duration.zero);

      final job = bridge.written.last.jobs.single;
      expect(job.label, 'api');
      expect(job.status, WidgetJobStatus.failure);
    },
  );

  test('logout clears the widget snapshot', () async {
    final c = await container();
    await c
        .read(authNotifierProvider.notifier)
        .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt');
    await c.read(authNotifierProvider.notifier).logout();
    expect(bridge.clears, 1);
  });
}
