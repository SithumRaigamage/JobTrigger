import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_screen.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_summaries_notifier.dart';

class _Repo implements SonarQubeRepository {
  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  _Repo(this.projects);

  final List<SonarQubeProject> projects;
  final Map<String, SonarQubeProjectSummary> summaries = {};
  Result<Map<String, SonarQubeProjectSummary>, AppFailure>? summaryResult;
  final List<List<String>> summaryAsks = [];

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async =>
      Ok(SonarQubeProjectsPage(projects: projects, total: projects.length));

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async {
    summaryAsks.add(projectKeys);
    return summaryResult ??
        Ok({
          for (final k in projectKeys)
            k:
                summaries[k] ??
                const SonarQubeProjectSummary(gate: QualityGateState.none),
        });
  }

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) async => const Ok([]);

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c',
    label: 'Local',
    baseUrl: 'http://sonar.test',
    secret: 't',
  );
}

class _Saved extends SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async => const [];
}

SonarQubeProject _p(String key, String name, {int? hoursAgo}) =>
    SonarQubeProject(
      key: key,
      name: name,
      lastAnalysisDate: hoursAgo == null
          ? null
          : DateTime.now().subtract(Duration(hours: hoursAgo)),
    );

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        activeSonarQubeCredentialNotifierProvider.overrideWith(_Credential.new),
        sonarQubeCredentialsNotifierProvider.overrideWith(_Saved.new),
        sonarQubeRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeProjectScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The vertical order of the project names on screen.
List<String> _order(WidgetTester tester, List<String> names) {
  final tops = {for (final n in names) n: tester.getTopLeft(find.text(n)).dy};
  return (tops.keys.toList()..sort((a, b) => tops[a]!.compareTo(tops[b]!)));
}

void main() {
  _Repo repo() {
    final r = _Repo([
      _p('ok', 'Healthy', hoursAgo: 5),
      _p('bad', 'Broken', hoursAgo: 1),
      _p('new', 'Untouched'),
      _p('warn', 'Shaky', hoursAgo: 9),
    ]);
    r.summaries.addAll({
      'ok': const SonarQubeProjectSummary(
        gate: QualityGateState.passed,
        bugs: 0,
        vulnerabilities: 0,
        codeSmells: 4,
        coverage: 81.6,
      ),
      'bad': const SonarQubeProjectSummary(
        gate: QualityGateState.failed,
        bugs: 3,
        vulnerabilities: 1,
        codeSmells: 20,
      ),
      'warn': const SonarQubeProjectSummary(gate: QualityGateState.warning),
    });
    return r;
  }

  testWidgets('each card shows its gate verdict and headline numbers', (
    tester,
  ) async {
    await _pump(tester, repo());

    expect(find.text('Passed'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Not analyzed'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget); // coverage, rounded
    expect(find.text('20'), findsOneWidget); // code smells of the failing one
    expect(find.text('3'), findsOneWidget);
    // A figure the server did not compute is a dash, never a zero.
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('the numbers are loaded once for every project, in one go', (
    tester,
  ) async {
    final r = repo();
    await _pump(tester, r);

    expect(r.summaryAsks, hasLength(1));
    expect(r.summaryAsks.single, containsAll(['ok', 'bad', 'new', 'warn']));
  });

  testWidgets('sorting by quality gate puts failing projects first', (
    tester,
  ) async {
    await _pump(tester, repo());

    await tester.tap(find.text('Sort: Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quality gate').last);
    await tester.pumpAndSettle();

    expect(_order(tester, ['Healthy', 'Broken', 'Untouched', 'Shaky']), [
      'Broken',
      'Shaky',
      'Healthy',
      'Untouched',
    ]);
  });

  testWidgets('sorting by last analysed puts the newest first, undated last', (
    tester,
  ) async {
    await _pump(tester, repo());

    await tester.tap(find.text('Sort: Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last analysed').last);
    await tester.pumpAndSettle();

    expect(_order(tester, ['Healthy', 'Broken', 'Untouched', 'Shaky']), [
      'Broken',
      'Healthy',
      'Shaky',
      'Untouched',
    ]);
  });

  testWidgets('the default order is by name', (tester) async {
    await _pump(tester, repo());

    expect(_order(tester, ['Healthy', 'Broken', 'Untouched', 'Shaky']), [
      'Broken',
      'Healthy',
      'Shaky',
      'Untouched',
    ]);
  });

  testWidgets('"Failing only" keeps just the failed and warning projects', (
    tester,
  ) async {
    await _pump(tester, repo());

    await tester.tap(find.text('Failing only'));
    await tester.pumpAndSettle();

    expect(find.text('Broken'), findsOneWidget);
    expect(find.text('Shaky'), findsOneWidget);
    expect(find.text('Healthy'), findsNothing);
    expect(find.text('Untouched'), findsNothing);

    await tester.tap(find.text('Failing only'));
    await tester.pumpAndSettle();
    expect(find.text('Healthy'), findsOneWidget);
  });

  testWidgets('"Failing only" with none failing says so as good news', (
    tester,
  ) async {
    final r = _Repo([_p('ok', 'Healthy', hoursAgo: 1)]);
    r.summaries['ok'] = const SonarQubeProjectSummary(
      gate: QualityGateState.passed,
    );
    await _pump(tester, r);

    await tester.tap(find.text('Failing only'));
    await tester.pumpAndSettle();

    expect(
      find.text('No projects are failing their quality gate'),
      findsOneWidget,
    );
  });

  testWidgets('if the numbers cannot be loaded the list still works', (
    tester,
  ) async {
    final r = repo()..summaryResult = const Err(NetworkFailure());
    await _pump(tester, r);

    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Broken'), findsOneWidget);
    expect(find.text('Passed'), findsNothing);
  });

  group('SonarQubeSummariesNotifier', () {
    ProviderContainer container(_Repo r) {
      final c = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [sonarQubeRepositoryProvider.overrideWithValue(r)],
      );
      addTearDown(c.dispose);
      c.listen(sonarQubeSummariesNotifierProvider, (_, _) {});
      return c;
    }

    test('asks only for projects it does not have yet', () async {
      final r = repo();
      final c = container(r);
      final n = c.read(sonarQubeSummariesNotifierProvider.notifier);

      await n.ensure(['ok', 'bad']);
      await n.ensure(['ok', 'bad', 'warn']);
      await n.ensure(['ok']); // nothing new: no request

      expect(r.summaryAsks, [
        ['ok', 'bad'],
        ['warn'],
      ]);
      expect(c.read(sonarQubeSummariesNotifierProvider).byKey.keys, [
        'ok',
        'bad',
        'warn',
      ]);
    });

    test('a failure is recorded and a later call retries it', () async {
      final r = repo()..summaryResult = const Err(NetworkFailure());
      final c = container(r);
      final n = c.read(sonarQubeSummariesNotifierProvider.notifier);

      await n.ensure(['ok']);
      var state = c.read(sonarQubeSummariesNotifierProvider);
      expect(state.failure, isA<NetworkFailure>());
      expect(state.byKey, isEmpty);
      expect(state.isLoading, isFalse);

      r.summaryResult = null;
      await n.ensure(['ok']);
      state = c.read(sonarQubeSummariesNotifierProvider);
      expect(state.failure, isNull);
      expect(state.byKey.keys, ['ok']);
    });
  });
}
