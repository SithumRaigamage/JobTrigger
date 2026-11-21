import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/server_status.dart';
import 'package:job_trigger/presentation/common_widgets/status_indicator.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/features/home/job_search_notifier.dart';
import 'package:job_trigger/presentation/features/home/reachability_watcher.dart';
import 'package:job_trigger/presentation/features/home/server_status_provider.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../support/fake_jenkins_repository.dart';

/// US-TREE-01/03/04/05: what Home shows for each state of the tree.
const _base = 'https://jenkins.test';
const _folder = JenkinsJob(
  name: 'Projects',
  url: '$_base/job/Projects/',
  jobs: [],
);
const _job = JenkinsJob(
  name: 'deploy',
  url: '$_base/job/deploy/',
  color: 'blue',
);
const _nested = JenkinsJob(
  name: 'api-tests',
  url: '$_base/job/Projects/job/api-tests/',
  color: 'red',
);

const _server = JenkinsServer(
  id: 's1',
  serverName: 'Acme',
  jenkinsURL: _base,
  username: 'u',
  secret: 'fixture-secret',
);

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => _server;
}

class _Saved extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async => const [_server];
}

/// One result per folder URL (null = root), changeable between calls.
class _Repo extends FakeJenkinsRepository {
  final results = <String?, Result<List<JenkinsJob>, AppFailure>>{
    null: const Ok([_folder, _job]),
    _folder.url: const Ok([_nested]),
  };
  final fetched = <String?>[];

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async {
    fetched.add(folderUrl);
    return results[folderUrl] ?? const Ok([]);
  }

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async => Ok([
    _folder.copyWith(jobs: const [_nested]),
    _job,
  ]);
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Repo repo, {
  ServerStatus? status,
}) async {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      if (status != null)
        serverStatusProvider.overrideWith((ref) async => status),
      jenkinsRepositoryProvider.overrideWithValue(repo),
      activeServerNotifierProvider.overrideWith(_Server.new),
      credentialsNotifierProvider.overrideWith(_Saved.new),
      reachabilityWatcherProvider.overrideWith((ref) {}),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (_, state) =>
            Scaffold(body: Text('detail ${(state.extra! as JenkinsJob).name}')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets('a folder reads differently from a job with a status', (
    tester,
  ) async {
    await _pump(tester, _Repo());

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('deploy'), findsOneWidget);
    expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('deploy'),
          matching: find.byType(InkWell),
        ),
        matching: find.byType(StatusIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an empty server says "No jobs found", not an error', (
    tester,
  ) async {
    final repo = _Repo()..results[null] = const Ok([]);
    await _pump(tester, repo);

    expect(find.text('No jobs found'), findsOneWidget);
    expect(find.text('Retry Connection'), findsNothing);
  });

  testWidgets('a failed load shows why with Retry, and Retry reloads the '
      'same folder', (tester) async {
    final repo = _Repo()..results[_folder.url] = const Err(ServerFailure(500));
    final container = await _pump(tester, repo);
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_folder);
    await tester.pumpAndSettle();

    // US-TREE-02: the trail from the root to this folder.
    expect(find.text('Home / Projects'), findsOneWidget);
    expect(find.text(const ServerFailure(500).message), findsOneWidget);
    expect(find.text('No jobs found'), findsNothing);
    expect(find.byIcon(Icons.search_off_rounded), findsNothing);

    repo.results[_folder.url] = const Ok([_nested]);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();

    expect(repo.fetched.last, _folder.url);
    expect(find.text('api-tests'), findsOneWidget);
    expect(container.read(folderBreadcrumbNotifierProvider), hasLength(1));
  });

  testWidgets('a search with no matches says so', (tester) async {
    final container = await _pump(tester, _Repo());

    container.read(jobSearchNotifierProvider.notifier).setQuery('zzz');
    await tester.pumpAndSettle();

    expect(find.text('No results for "zzz"'), findsOneWidget);
  });

  testWidgets('a search result shows its folder and opens the job', (
    tester,
  ) async {
    final container = await _pump(tester, _Repo());

    container.read(jobSearchNotifierProvider.notifier).setQuery('api');
    await tester.pumpAndSettle();
    expect(find.text('api-tests'), findsOneWidget);
    expect(find.textContaining('Projects'), findsWidgets);

    await tester.tap(find.text('api-tests'));
    await tester.pumpAndSettle();
    expect(find.text('detail api-tests'), findsOneWidget);
  });

  testWidgets('clearing a search returns to the folder you were in', (
    tester,
  ) async {
    final container = await _pump(tester, _Repo());
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_folder);
    await tester.pumpAndSettle();

    container.read(jobSearchNotifierProvider.notifier).setQuery('deploy');
    await tester.pumpAndSettle();
    container.read(jobSearchNotifierProvider.notifier).clear();
    await tester.pumpAndSettle();

    expect(find.text('api-tests'), findsOneWidget);
    expect(find.text('deploy'), findsNothing);
  });

  testWidgets('a failed refresh keeps the list and says why', (tester) async {
    final repo = _Repo();
    final container = await _pump(tester, repo);
    container.listen(currentToastProvider, (_, _) {});
    expect(find.text('deploy'), findsOneWidget);

    repo.results[null] = const Err(ServerFailure(500));
    await tester.fling(find.text('deploy'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    // US-TREE-04 "Refresh failure": the loaded list stays visible, and a
    // toast says why.
    expect(find.text('deploy'), findsOneWidget);
    expect(find.text('Retry Connection'), findsNothing);
    final toast = container.read(currentToastProvider);
    expect(toast?.title, 'Refresh failed');
    expect(toast?.message, const ServerFailure(500).message);
    await tester.pump(const Duration(seconds: 4));
  });

  // US-JX-18 "Quiet down".
  testWidgets('a server preparing for shutdown shows a banner on Home', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo(),
      status: const ServerStatus(version: '2.480', quietingDown: true),
    );

    expect(
      find.textContaining('Jenkins is preparing for shutdown'),
      findsOneWidget,
    );
  });

  testWidgets('a running server shows no shutdown banner', (tester) async {
    await _pump(tester, _Repo(), status: const ServerStatus(version: '2.480'));

    expect(find.textContaining('preparing for shutdown'), findsNothing);
  });
}
