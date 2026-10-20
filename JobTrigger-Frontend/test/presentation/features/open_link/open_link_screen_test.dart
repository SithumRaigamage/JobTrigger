import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/open_link/open_link_screen.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prod = JenkinsServer(
  id: 'prod',
  serverName: 'Prod',
  jenkinsURL: 'https://ci.example.com',
  username: 'u',
  secret: 's',
);
const _staging = JenkinsServer(
  id: 'staging',
  serverName: 'Staging',
  jenkinsURL: 'https://staging.example.com',
  username: 'u',
  secret: 's',
);

class _Servers implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([_prod, _staging]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Active extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => _prod;

  @override
  Future<void> setActiveServer(JenkinsServer server) async => state = server;
}

/// Mirrors the app's routes with placeholder screens that show what they
/// were opened with.
GoRouter _router(String link) => GoRouter(
  initialLocation: Uri(
    path: AppRoutes.openLink,
    queryParameters: {'url': link},
  ).toString(),
  routes: [
    GoRoute(
      path: AppRoutes.openLink,
      builder: (context, state) =>
          OpenLinkScreen(link: state.uri.queryParameters['url'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const Text('HOME'),
    ),
    GoRoute(
      path: AppRoutes.jobDetail,
      builder: (context, state) =>
          Text('JOB ${(state.extra! as JenkinsJob).url}'),
    ),
    GoRoute(
      path: AppRoutes.buildDetail,
      builder: (context, state) =>
          Text('BUILD ${(state.extra! as JenkinsBuild).url}'),
    ),
    GoRoute(
      path: AppRoutes.buildLog,
      builder: (context, state) =>
          Text('LOG ${(state.extra! as JenkinsBuild).url}'),
    ),
  ],
);

Future<ProviderContainer> _pump(WidgetTester tester, String link) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer(
    overrides: [
      credentialsRepositoryProvider.overrideWithValue(_Servers()),
      activeServerNotifierProvider.overrideWith(_Active.new),
    ],
  );
  addTearDown(container.dispose);
  // In the app the Jenkins client keeps this alive; here, a listener does.
  container.listen(activeServerNotifierProvider, (_, _) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: _router(link)),
    ),
  );
  // Not pumpAndSettle: the loading spinner behind a confirmation dialog
  // never settles.
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a build link on the active server opens that build', (
    tester,
  ) async {
    await _pump(tester, 'https://ci.example.com/job/team/job/api/42/');

    expect(
      find.text('BUILD https://ci.example.com/job/team/job/api/42/'),
      findsOneWidget,
    );
  });

  testWidgets('a console link opens the log', (tester) async {
    await _pump(tester, 'https://ci.example.com/job/api/7/console');

    expect(find.text('LOG https://ci.example.com/job/api/7/'), findsOneWidget);
  });

  testWidgets('a link on another saved server asks before switching', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      'https://staging.example.com/job/api/',
    );

    expect(find.text('Switch to Staging?'), findsOneWidget);
    await tester.tap(find.text('Switch'));
    await _settle(tester);

    expect(container.read(activeServerNotifierProvider)?.id, 'staging');
    expect(
      find.text('JOB https://staging.example.com/job/api/'),
      findsOneWidget,
    );
  });

  testWidgets('declining the switch goes Home without changing servers', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      'https://staging.example.com/job/api/',
    );

    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    expect(container.read(activeServerNotifierProvider)?.id, 'prod');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('a link carrying credentials is refused', (tester) async {
    await _pump(tester, 'https://me:pw@ci.example.com/job/api/');
    expect(
      find.textContaining('contains a username and password'),
      findsOneWidget,
    );
  });

  testWidgets('a link to an unknown server is refused', (tester) async {
    await _pump(tester, 'https://evil.example.net/job/api/');
    expect(find.textContaining('No saved server matches'), findsOneWidget);
  });
}
