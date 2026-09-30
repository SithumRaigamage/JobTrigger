import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_view.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/features/home/views_notifier.dart';
import 'package:job_trigger/presentation/features/home/visible_jobs_provider.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

const _all = JenkinsView(name: 'all', url: 'https://a.test/', isPrimary: true);
const _pipelines = JenkinsView(
  name: 'Pipelines',
  url: 'https://a.test/view/Pipelines/',
);
const _folder = JenkinsJob(
  name: 'team',
  url: 'https://a.test/job/team/',
  jobs: [],
);

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 'a',
    serverName: 'a',
    jenkinsURL: 'https://a.test',
    username: 'u',
    secret: 's',
  );
}

class _Repo extends FakeJenkinsRepository {
  final fetched = <String?>[];

  @override
  Future<Result<List<JenkinsView>, AppFailure>> fetchViews() async =>
      const Ok([_all, _pipelines]);

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async {
    fetched.add(folderUrl);
    return Ok(switch (folderUrl) {
      null => const [
        _folder,
        JenkinsJob(name: 'freestyle', url: 'https://a.test/job/freestyle/'),
      ],
      'https://a.test/view/Pipelines/' => const [
        JenkinsJob(name: 'pipeline-a', url: 'https://a.test/job/pipeline-a/'),
      ],
      _ => const <JenkinsJob>[],
    });
  }
}

ProviderContainer _container(_Repo repo) {
  final container = ProviderContainer(
    overrides: [
      jenkinsRepositoryProvider.overrideWithValue(repo),
      activeServerNotifierProvider.overrideWith(_Server.new),
    ],
  );
  addTearDown(container.dispose);
  container
    ..listen(visibleJobsProvider, (_, _) {})
    ..listen(selectedViewNotifierProvider, (_, _) {})
    ..listen(folderBreadcrumbNotifierProvider, (_, _) {});
  return container;
}

Future<List<String>> _names(ProviderContainer container) async {
  for (var i = 0; i < 5 && container.read(visibleJobsProvider).isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return [
    for (final job in container.read(visibleJobsProvider).requireValue)
      job.name,
  ];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('selecting a view lists it at the root, persisted per server', () async {
    final repo = _Repo();
    final container = _container(repo);
    expect(await _names(container), ['team', 'freestyle']);

    await container
        .read(selectedViewNotifierProvider.notifier)
        .select(_pipelines);

    expect(await _names(container), ['pipeline-a']);
    expect(repo.fetched.last, 'https://a.test/view/Pipelines/');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('selected_view_a'),
      'https://a.test/view/Pipelines/',
    );

    // Back to the primary view is the plain root, and forgets the choice.
    await container.read(selectedViewNotifierProvider.notifier).select(_all);
    expect(await _names(container), ['team', 'freestyle']);
    expect(prefs.getString('selected_view_a'), isNull);
  });

  test('switching views resets the folder breadcrumb', () async {
    final container = _container(_Repo());
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_folder);
    expect(container.read(folderBreadcrumbNotifierProvider), hasLength(1));

    await container
        .read(selectedViewNotifierProvider.notifier)
        .select(_pipelines);

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  testWidgets('the Home title is a view picker', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jenkinsRepositoryProvider.overrideWithValue(_Repo()),
          activeServerNotifierProvider.overrideWith(_Server.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('All jobs'), findsOneWidget);

    await tester.tap(find.text('All jobs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pipelines'));
    await tester.pumpAndSettle();

    expect(find.text('pipeline-a'), findsOneWidget);
    expect(find.text('freestyle'), findsNothing);
  });
}
