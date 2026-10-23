import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

/// P14-07: Home as redesigned (`UI-UX/screens/05-home-jenkins-dark`).
const _jobs = [
  JenkinsJob(
    name: 'api',
    url: 'https://a.test/job/api/',
    color: 'blue_anime',
    lastBuild: JenkinsBuild(number: 7, url: 'u', timestamp: 0, building: true),
  ),
  JenkinsJob(
    name: 'web',
    url: 'https://a.test/job/web/',
    color: 'red',
    lastBuild: JenkinsBuild(number: 12, url: 'u', timestamp: 0),
  ),
  JenkinsJob(
    name: 'billing',
    url: 'https://a.test/job/billing/',
    color: 'blue',
  ),
  JenkinsJob(name: 'docs', url: 'https://a.test/job/docs/', color: 'blue'),
];

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 'a',
    serverName: 'Acme production',
    jenkinsURL: 'https://a.test',
    username: 'u',
    secret: 's',
  );
}

class _Repo extends FakeJenkinsRepository {
  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async => const Ok(_jobs);

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobStatus(String url) async =>
      Ok(_jobs.firstWhere((job) => job.url == url));
}

Future<void> _pumpHome(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const Scaffold(body: Text('settings')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeServerNotifierProvider.overrideWith(_Server.new),
        jenkinsRepositoryProvider.overrideWithValue(_Repo()),
      ],
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
  // Not pumpAndSettle: the building job's status dot pulses for as long
  // as it builds.
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'pinned_jobs_a': '[{"url":"https://a.test/job/web/","label":"web"}]',
    });
  });

  testWidgets('the summary strip counts running, failing and passing jobs', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Running'), findsWidgets);
    expect(find.text('Failing'), findsOneWidget);
    expect(find.text('Passing'), findsOneWidget);
    // One building, one failed, two passed.
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('a pin shows its last build and status as a pill', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('#12'), findsWidgets);
    expect(find.text('Failed'), findsWidgets);
  });

  testWidgets('the server chip names the server and leads to Settings', (
    tester,
  ) async {
    await _pumpHome(tester);

    final chip = find.bySemanticsLabel(RegExp('^Server Acme production'));
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await _settle(tester);
    expect(find.text('settings'), findsOneWidget);
  });
}
