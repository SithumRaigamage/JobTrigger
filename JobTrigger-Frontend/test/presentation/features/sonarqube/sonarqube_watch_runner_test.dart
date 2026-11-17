import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/cache/sonarqube_watch_store.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis_status.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue_grouping.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_watch.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_watch_runner.dart';

import '../../../support/sonarqube_insights_defaults.dart';

/// P10-19: one shared pass over every gate watch, used by the in-app timer
/// and the background task.
class _MemStore extends SonarQubeWatchStore {
  _MemStore([List<SonarQubeProjectWatch>? watches]) : items = watches ?? [];

  List<SonarQubeProjectWatch> items;

  @override
  Future<List<SonarQubeProjectWatch>> load() async => List.of(items);

  @override
  Future<void> save(List<SonarQubeProjectWatch> watches) async {
    items = List.of(watches);
  }
}

class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  _Repo({required this.gate, required this.analysis, this.gateError = false});

  QualityGateState gate;
  String? analysis;
  bool gateError;

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) async => gateError
      ? const Err(AuthFailure())
      : Ok(
          SonarQubeQualityGate(
            state: gate,
            conditions: gate == QualityGateState.failed
                ? const [
                    QualityGateCondition(
                      metricKey: 'bugs',
                      comparator: 'GT',
                      threshold: '0',
                      actual: '3',
                      failed: true,
                    ),
                  ]
                : const [],
          ),
        );

  @override
  Future<Result<SonarQubeAnalysisStatus, AppFailure>> fetchAnalysisStatus(
    String projectKey,
  ) async => Ok(
    SonarQubeAnalysisStatus(
      current: SonarQubeCeTask(
        status: 'SUCCESS',
        executedAt: analysis == null ? null : DateTime.parse(analysis!),
      ),
    ),
  );

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) => throw UnimplementedError();

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
    SonarQubeIssueGrouping grouping = SonarQubeIssueGrouping.none,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) => throw UnimplementedError();
}

const _watch = SonarQubeProjectWatch(
  credentialId: 'c1',
  projectKey: 'acme:api',
  projectName: 'API Gateway',
);

void main() {
  test(
    'notifies once per new failing analysis and stores what it saw',
    () async {
      final store = _MemStore([_watch]);
      final repo = _Repo(
        gate: QualityGateState.failed,
        analysis: '2026-11-17T09:00:00.000Z',
      );
      final sent = <SonarQubeGateNotification>[];

      final remaining = await runSonarQubeWatchCheck(
        store: store,
        repositoryFor: (_) async => repo,
        notify: (notification) async => sent.add(notification),
      );

      expect(sent, hasLength(1));
      expect(sent.single.projectKey, 'acme:api');
      expect(remaining.single.lastAnalysis, '2026-11-17T09:00:00.000Z');

      // A second pass on the same analysis stays quiet.
      await runSonarQubeWatchCheck(
        store: store,
        repositoryFor: (_) async => repo,
        notify: (notification) async => sent.add(notification),
      );
      expect(sent, hasLength(1));
    },
  );

  test(
    'a failing gate with no analysis time does not re-notify every pass',
    () async {
      final store = _MemStore([_watch]);
      final repo = _Repo(gate: QualityGateState.failed, analysis: null);
      final sent = <SonarQubeGateNotification>[];

      for (var i = 0; i < 3; i++) {
        await runSonarQubeWatchCheck(
          store: store,
          repositoryFor: (_) async => repo,
          notify: (notification) async => sent.add(notification),
        );
      }

      expect(sent, hasLength(1));
    },
  );

  test('a transient failure keeps the watch untouched', () async {
    final store = _MemStore([_watch]);
    final repo = _Repo(
      gate: QualityGateState.failed,
      analysis: '2026-11-17T09:00:00.000Z',
      gateError: true,
    );

    final remaining = await runSonarQubeWatchCheck(
      store: store,
      repositoryFor: (_) async => repo,
      notify: (_) async {},
    );

    expect(remaining, hasLength(1));
    expect(remaining.single.lastAnalysis, isNull);
  });

  test('a deleted credential drops its watches', () async {
    final store = _MemStore([_watch]);
    final sent = <SonarQubeGateNotification>[];

    final remaining = await runSonarQubeWatchCheck(
      store: store,
      repositoryFor: (_) async => null,
      notify: (notification) async => sent.add(notification),
    );

    expect(remaining, isEmpty);
    expect(sent, isEmpty);
    expect(store.items, isEmpty);
  });

  test('an unreachable credential keeps its watches for next time', () async {
    final store = _MemStore([_watch]);

    final remaining = await runSonarQubeWatchCheck(
      store: store,
      repositoryFor: (_) async => throw StateError('offline'),
      notify: (_) async {},
    );

    expect(remaining, hasLength(1));
    expect(store.items, hasLength(1));
  });

  test("a watch added during a pass survives the pass's save", () async {
    final store = _MemStore([_watch]);
    final repo = _Repo(
      gate: QualityGateState.passed,
      analysis: '2026-11-17T09:00:00.000Z',
    );
    const addedThoughOut = SonarQubeProjectWatch(
      credentialId: 'c1',
      projectKey: 'acme:web',
      projectName: 'Website',
    );

    await runSonarQubeWatchCheck(
      store: store,
      repositoryFor: (_) async {
        // The user adds a second watch while the first is being checked.
        store.items = [...store.items, addedThoughOut];
        return repo;
      },
      notify: (_) async {},
    );

    expect(store.items.map((w) => w.projectKey), ['acme:api', 'acme:web']);
  });
}
