import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/features/home/pinned_jobs_notifier.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

JenkinsServer _server(String id) => JenkinsServer(
  id: id,
  serverName: id,
  jenkinsURL: 'https://$id.test',
  username: 'u',
  secret: 's',
);

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => _server('a');

  @override
  Future<void> setActiveServer(JenkinsServer server) async => state = server;
}

const _api = JenkinsJob(name: 'api', url: 'https://a.test/job/api/');

class _Repo extends FakeJenkinsRepository {
  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async => const Ok([_api]);

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      jobUrl == _api.url
      ? const Ok(
          JenkinsJob(
            name: 'api',
            url: 'https://a.test/job/api/',
            color: 'blue',
            lastBuild: JenkinsBuild(number: 41, url: 'u', timestamp: 0),
          ),
        )
      : const Err(NotFoundFailure());
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [activeServerNotifierProvider.overrideWith(_Server.new)],
  );
  addTearDown(container.dispose);
  container.listen(pinnedJobsNotifierProvider, (_, _) {});
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('pins persist per server and reload on server switch', () async {
    final container = _container();
    final notifier = container.read(pinnedJobsNotifierProvider.notifier);

    expect(await notifier.toggle(_api), isTrue);
    expect(container.read(pinnedJobsNotifierProvider).single.label, 'api');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pinned_jobs_a'), contains('job/api'));

    await container
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(_server('b'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(pinnedJobsNotifierProvider), isEmpty);

    await container
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(_server('a'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(pinnedJobsNotifierProvider), hasLength(1));
  });

  test('toggling again unpins', () async {
    final container = _container();
    final notifier = container.read(pinnedJobsNotifierProvider.notifier);
    await notifier.toggle(_api);

    expect(await notifier.toggle(_api), isFalse);
    expect(container.read(pinnedJobsNotifierProvider), isEmpty);
  });

  test('corrupt stored pins are dropped, not a crash', () async {
    SharedPreferences.setMockInitialValues({'pinned_jobs_a': '{not json'});
    final container = _container();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(pinnedJobsNotifierProvider), isEmpty);
  });

  testWidgets('Home shows a Pinned section with live status and stale pins', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'pinned_jobs_a':
          '[{"url":"https://a.test/job/api/","label":"api"},'
          '{"url":"https://a.test/job/gone/","label":"gone"}]',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeServerNotifierProvider.overrideWith(_Server.new),
          jenkinsRepositoryProvider.overrideWithValue(_Repo()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pinned'), findsOneWidget);
    expect(find.text('All jobs'), findsOneWidget);
    expect(find.text('#41'), findsWidgets);
    expect(
      find.text('Not found — it may have been deleted or renamed'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Unpin gone'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not found'), findsNothing);
  });
}
