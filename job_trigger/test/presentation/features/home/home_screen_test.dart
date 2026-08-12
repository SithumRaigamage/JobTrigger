import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';

class _FakeJenkinsRepository implements JenkinsRepository {
  _FakeJenkinsRepository(this._jobs);

  final List<JenkinsJob> _jobs;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async =>
      Ok(_jobs);

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) =>
      throw UnimplementedError();

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) =>
      throw UnimplementedError();
}

void main() {
  // P6-06: on Android, the system back gesture must walk up one breadcrumb
  // level at a time (like a file browser) instead of immediately popping
  // HomeScreen off the navigator, since folder drill-down is in-place
  // widget state, not a route per folder.
  testWidgets(
    'system back navigates up one breadcrumb level instead of popping the route',
    (tester) async {
      const folder = JenkinsJob(
        name: 'Projects',
        url: 'https://jenkins.test/job/Projects/',
        jobs: [],
      );
      final repo = _FakeJenkinsRepository([folder]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            // A base route beneath HomeScreen, matching the real app
            // (Home isn't the Navigator's root -- ToolSelection is) so
            // `Navigator.canPop()` is structurally true and this test
            // actually exercises `PopScope`'s interception, not just an
            // unrelated "can't pop a single-route stack" no-op.
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const HomeScreen(),
                      ),
                    ),
                    child: const Text('go'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Drill into the folder only once HomeScreen is mounted and watching
      // the provider -- doing this beforehand would let the (non-keepAlive)
      // notifier auto-dispose and reset before anything ever observes it,
      // the same pitfall hit repeatedly with polling notifiers in Phase 5.
      container
          .read(folderBreadcrumbNotifierProvider.notifier)
          .navigateInto(folder);
      await tester.pumpAndSettle();

      expect(
        container.read(folderBreadcrumbNotifierProvider),
        hasLength(1),
      );

      final navigatorState = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      final popped = await navigatorState.maybePop();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
      // The route itself is still there -- HomeScreen intercepted the pop.
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('system back at the root pops the route normally', (
    tester,
  ) async {
    final repo = _FakeJenkinsRepository(const []);
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const HomeScreen(),
                    ),
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final navigatorState = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    final popped = await navigatorState.maybePop();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    // At the root breadcrumb, PopScope let the real pop through -- HomeScreen
    // is gone and the base route is back.
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('go'), findsOneWidget);
  });
}
