import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/history_entry.dart';
import 'package:job_trigger/domain/jenkins/history_filter.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/history/global_history_notifier.dart';
import 'package:job_trigger/presentation/features/history/global_history_screen.dart';
import 'package:job_trigger/presentation/features/history/job_history_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

import '../../../support/fake_jenkins_repository.dart';

/// US-HIST-01/02: opening a build from history, and the edge states.
const _jobUrl = 'https://a.test/job/api/';

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 'a',
    serverName: 'a',
    jenkinsURL: 'https://a.test',
    username: 'u',
    secret: 'fixture-secret',
  );
}

JenkinsBuild _build(int number) => JenkinsBuild(
  number: number,
  url: '$_jobUrl$number/',
  result: 'SUCCESS',
  timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
  duration: 1000,
);

class _History extends GlobalHistoryNotifier {
  _History(this.result);

  final Result<List<HistoryEntry>, AppFailure> result;

  @override
  Future<List<HistoryEntry>> build() async =>
      result.fold((entries) => entries, (failure) => throw failure);
}

class _OneBuild extends FakeJenkinsRepository {
  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) async => Ok(start == 0 ? [_build(1)] : const []);
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: AppRoutes.buildDetail,
        builder: (_, state) => Scaffold(
          body: Text('build ${(state.extra! as JenkinsBuild).number}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        activeServerNotifierProvider.overrideWith(_Server.new),
        ...overrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a global history entry opens that build', (tester) async {
    await _pump(tester, const GlobalHistoryScreen(), [
      globalHistoryNotifierProvider.overrideWith(
        () => _History(Ok([HistoryEntry(jobName: 'api', build: _build(7))])),
      ),
    ]);

    await tester.tap(find.text('api #7'));
    await tester.pumpAndSettle();

    expect(find.text('build 7'), findsOneWidget);
  });

  testWidgets('a failed job tree shows the error, not an empty history', (
    tester,
  ) async {
    await _pump(tester, const GlobalHistoryScreen(), [
      globalHistoryNotifierProvider.overrideWith(
        () => _History(const Err(ServerFailure(500))),
      ),
    ]);

    expect(find.text(const ServerFailure(500).message), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);
  });

  testWidgets('a job with one build lists it and opens it', (tester) async {
    await _pump(
      tester,
      const JobHistoryScreen(
        job: JenkinsJob(name: 'api', url: _jobUrl),
      ),
      [jenkinsRepositoryProvider.overrideWithValue(_OneBuild())],
    );

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('End of history · 1 build'), findsOneWidget);

    await tester.tap(find.text('#1'));
    await tester.pumpAndSettle();
    expect(find.text('build 1'), findsOneWidget);
  });
}
