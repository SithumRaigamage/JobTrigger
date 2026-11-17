import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../domain/sonarqube/sonarqube_analysis.dart';
import '../../domain/sonarqube/sonarqube_analysis_status.dart';
import '../../domain/sonarqube/sonarqube_hotspot.dart';
import '../../domain/sonarqube/sonarqube_branch_ref.dart';
import '../../domain/sonarqube/sonarqube_issue.dart';
import '../../domain/sonarqube/sonarqube_issue_grouping.dart';
import '../../domain/sonarqube/sonarqube_measure_history.dart';
import '../../domain/sonarqube/sonarqube_worst_files.dart';
import '../../domain/sonarqube/sonarqube_measure_delta.dart';
import '../../domain/sonarqube/sonarqube_metrics.dart';
import '../../domain/sonarqube/sonarqube_server_info.dart';
import '../../domain/sonarqube/sonarqube_project.dart';
import '../../domain/sonarqube/sonarqube_project_summary.dart';
import '../../domain/sonarqube/sonarqube_quality_gate.dart';
import '../../domain/sonarqube/sonarqube_repository.dart';
import 'demo_mode_notifier.dart';

part 'demo_sonarqube_repository.g.dart';

/// The demo's SonarQube (E2, PE-10): two projects, one passing its quality
/// gate and one failing it, with measures, issues and analyses. SonarQube is
/// read-only in the app, so there are no write actions to refuse.
class DemoSonarQubeRepository implements SonarQubeRepository {
  DemoSonarQubeRepository({DateTime Function()? clock})
    : _now = (clock ?? DateTime.now)();

  final DateTime _now;

  static const _good = 'demo-org_api';
  static const _bad = 'demo-org_app';

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async {
    if (page > 1) {
      return const Ok(SonarQubeProjectsPage(projects: [], total: 2));
    }
    return Ok(
      SonarQubeProjectsPage(
        total: 2,
        projects: [
          SonarQubeProject(
            key: _bad,
            name: 'Demo App',
            lastAnalysisDate: _now.subtract(const Duration(hours: 5)),
          ),
          SonarQubeProject(
            key: _good,
            name: 'Demo API',
            lastAnalysisDate: _now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) async {
    if (projectKey == _good) {
      return const Ok(
        SonarQubeQualityGate(
          state: QualityGateState.passed,
          conditions: [
            QualityGateCondition(
              metricKey: 'new_coverage',
              comparator: 'LT',
              threshold: '80',
              actual: '91.4',
              failed: false,
            ),
          ],
        ),
      );
    }
    if (projectKey != _bad) return const Err(SonarQubeProjectNotFoundFailure());
    return const Ok(
      SonarQubeQualityGate(
        state: QualityGateState.failed,
        conditions: [
          QualityGateCondition(
            metricKey: 'new_coverage',
            comparator: 'LT',
            threshold: '80',
            actual: '62.3',
            failed: true,
          ),
          QualityGateCondition(
            metricKey: 'new_vulnerabilities',
            comparator: 'GT',
            threshold: '0',
            actual: '2',
            failed: true,
          ),
          QualityGateCondition(
            metricKey: 'new_duplicated_lines_density',
            comparator: 'GT',
            threshold: '3',
            actual: '1.2',
            failed: false,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) async {
    if (projectKey == _good) {
      return const Ok({
        'coverage': '91.4',
        'bugs': '0',
        'vulnerabilities': '0',
        'code_smells': '12',
        'duplicated_lines_density': '0.8',
        'ncloc': '18240',
      });
    }
    if (projectKey != _bad) return const Err(SonarQubeProjectNotFoundFailure());
    return const Ok({
      'coverage': '62.3',
      'bugs': '3',
      'vulnerabilities': '2',
      'code_smells': '57',
      'duplicated_lines_density': '1.2',
      'ncloc': '41870',
    });
  }

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchMyIssues({
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) async {
    if (page > 1) return const Ok(SonarQubeIssuePage(issues: [], total: 0));
    // Two of the demo issues are "yours", so the list is never empty.
    const mine = {'demo-2', 'demo-3'};
    final matching = [
      for (final issue in _issues)
        if (mine.contains(issue.key) &&
            (filter.types.isEmpty || filter.types.contains(issue.type)) &&
            (filter.severities.isEmpty ||
                filter.severities.contains(issue.severity)))
          SonarQubeIssue(
            key: issue.key,
            type: issue.type,
            severity: issue.severity,
            message: issue.message,
            file: issue.file,
            line: issue.line,
            component: issue.component,
            rule: issue.rule,
            effort: issue.effort,
            tags: issue.tags,
            author: issue.author,
            status: issue.status,
            creationDate: issue.creationDate,
            project: _bad,
            projectName: 'Demo app',
          ),
    ];
    return Ok(SonarQubeIssuePage(issues: matching, total: matching.length));
  }

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> searchIssues(
    String term, {
    SonarQubeIssueSearchField field = SonarQubeIssueSearchField.rule,
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) async {
    if (page > 1) return const Ok(SonarQubeIssuePage(issues: [], total: 0));
    final needle = term.trim().toLowerCase();
    bool hit(SonarQubeIssue i) => switch (field) {
      SonarQubeIssueSearchField.rule => (i.rule ?? '').toLowerCase() == needle,
      SonarQubeIssueSearchField.tag => i.tags.any(
        (t) => t.toLowerCase() == needle,
      ),
      SonarQubeIssueSearchField.file => (i.file ?? '').toLowerCase() == needle,
      SonarQubeIssueSearchField.issueKey => i.key.toLowerCase() == needle,
    };
    final matching = [
      for (final issue in _issues)
        if (needle.isNotEmpty &&
            hit(issue) &&
            (filter.types.isEmpty || filter.types.contains(issue.type)) &&
            (filter.severities.isEmpty ||
                filter.severities.contains(issue.severity)))
          SonarQubeIssue(
            key: issue.key,
            type: issue.type,
            severity: issue.severity,
            message: issue.message,
            file: issue.file,
            line: issue.line,
            component: issue.component,
            rule: issue.rule,
            effort: issue.effort,
            tags: issue.tags,
            author: issue.author,
            status: issue.status,
            creationDate: issue.creationDate,
            project: _bad,
            projectName: 'Demo app',
          ),
    ];
    return Ok(SonarQubeIssuePage(issues: matching, total: matching.length));
  }

  @override
  Future<Result<SonarQubeAnalysisStatus, AppFailure>> fetchAnalysisStatus(
    String projectKey,
  ) async {
    if (projectKey != _good && projectKey != _bad) {
      return const Err(SonarQubeProjectNotFoundFailure());
    }
    // A finished analysis: the demo has no pending scan to show off.
    return Ok(
      SonarQubeAnalysisStatus(
        current: SonarQubeCeTask(
          status: 'SUCCESS',
          type: 'REPORT',
          executedAt: _now,
        ),
      ),
    );
  }

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchNewCodeMeasures(
    String projectKey,
  ) async {
    if (projectKey == _good) {
      return const Ok({
        'new_bugs': '0',
        'new_vulnerabilities': '0',
        'new_code_smells': '2',
        'new_coverage': '94.2',
        'new_duplicated_lines_density': '0',
        'new_lines': '180',
      });
    }
    if (projectKey != _bad) return const Err(SonarQubeProjectNotFoundFailure());
    return const Ok({
      'new_bugs': '1',
      'new_vulnerabilities': '0',
      'new_code_smells': '9',
      'new_coverage': '41.7',
      'new_duplicated_lines_density': '3.4',
      'new_lines': '620',
    });
  }

  @override
  Future<Result<List<SonarQubeMeasureDelta>, AppFailure>> fetchMeasureDeltas(
    String projectKey, {
    List<String> metricKeys = sonarQubeMeasureKeys,
  }) async {
    if (projectKey != _good && projectKey != _bad) {
      return const Err(SonarQubeProjectNotFoundFailure());
    }
    final worse = projectKey == _bad;
    return Ok([
      if (metricKeys.contains('coverage'))
        SonarQubeMeasureDelta(
          metricKey: 'coverage',
          previous: worse ? 66 : 90.9,
          current: worse ? 62.3 : 91.4,
        ),
      if (metricKeys.contains('bugs'))
        SonarQubeMeasureDelta(
          metricKey: 'bugs',
          previous: worse ? 1 : 0,
          current: worse ? 3 : 0,
        ),
      if (metricKeys.contains('code_smells'))
        SonarQubeMeasureDelta(
          metricKey: 'code_smells',
          previous: worse ? 48 : 13,
          current: worse ? 57 : 12,
        ),
    ]);
  }

  @override
  Future<Result<SonarQubeMeasureHistory, AppFailure>> fetchMeasureHistory(
    String projectKey,
    String metric,
  ) async => Ok(
    SonarQubeMeasureHistory(
      metric: metric,
      unit: sonarQubeTrendMetrics
          .firstWhere(
            (m) => m.metric == metric,
            orElse: () => SonarQubeTrendMetric(metric, metric, ''),
          )
          .unit,
      points: [
        SonarQubeMeasurePoint(date: DateTime(2026, 10, 1), value: 71),
        SonarQubeMeasurePoint(date: DateTime(2026, 10, 15), value: 74.5),
        SonarQubeMeasurePoint(date: DateTime(2026, 11, 1), value: 69.2),
        SonarQubeMeasurePoint(date: DateTime(2026, 11, 15), value: 77.8),
      ],
    ),
  );

  @override
  Future<Result<SonarQubeServerInfo, AppFailure>> fetchServerInfo() async =>
      const Ok(SonarQubeServerInfo(version: '10.6.0.92116', status: 'UP'));

  @override
  Future<Result<SonarQubeRefChoices, AppFailure>> fetchProjectRefs(
    String projectKey,
  ) async => Ok(
    parseSonarQubeRefs(
      branches: {
        'branches': [
          {'name': 'main', 'isMain': true},
          {'name': 'feature/login', 'isMain': false},
        ],
      },
      pullRequests: {
        'pullRequests': [
          {'key': '42', 'title': 'Add login'},
        ],
      },
    ),
  );

  @override
  Future<Result<SonarQubeWorstFiles, AppFailure>> fetchWorstFiles(
    String projectKey,
    SonarQubeFileMetric metric,
  ) async => Ok(
    SonarQubeWorstFiles(
      metric: metric.metric,
      unit: metric.unit,
      files: const [
        SonarQubeFileMeasures(path: 'src/legacy/report.ts', value: 0),
        SonarQubeFileMeasures(path: 'src/config/auth.ts', value: 12.5),
        SonarQubeFileMeasures(path: 'src/net/client.ts', value: 31.0),
      ],
    ),
  );

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchFileIssues(
    String componentKey,
  ) async => Ok(SonarQubeIssuePage(issues: _issues.take(2).toList(), total: 2));

  static const _hotspots = [
    SonarQubeHotspot(
      key: 'demo-h1',
      message: 'Make sure this password is not hard-coded.',
      status: 'TO_REVIEW',
      securityCategory: 'weak-cryptography',
      vulnerabilityProbability: 'HIGH',
      file: 'src/config/auth.ts',
      line: 18,
    ),
    SonarQubeHotspot(
      key: 'demo-h2',
      message: 'Make sure the permissive CORS header is intended.',
      status: 'REVIEWED',
      securityCategory: 'others',
      vulnerabilityProbability: 'MEDIUM',
      file: 'src/net/client.ts',
      line: 54,
    ),
  ];

  @override
  Future<Result<SonarQubeHotspotPage, AppFailure>> fetchHotspots(
    String projectKey, {
    bool reviewed = false,
    int page = 1,
  }) async {
    if (projectKey != _bad || page > 1) {
      return const Ok(SonarQubeHotspotPage(hotspots: [], total: 0));
    }
    final matching = [
      for (final hotspot in _hotspots)
        if (hotspot.isReviewed == reviewed) hotspot,
    ];
    return Ok(SonarQubeHotspotPage(hotspots: matching, total: matching.length));
  }

  @override
  Future<Result<SonarQubeHotspotDetail, AppFailure>> fetchHotspotDetail(
    String hotspotKey,
  ) async => const Ok(
    SonarQubeHotspotDetail(
      ruleName: 'Hard-coded credentials',
      snippet: [
        SonarQubeSourceLine(number: 18, code: 'const password = \'hunter2\';'),
      ],
    ),
  );

  static const _issues = [
    SonarQubeIssue(
      key: 'demo-1',
      type: 'VULNERABILITY',
      severity: 'CRITICAL',
      message: 'Make sure this password is not hard-coded.',
      file: 'src/config/auth.ts',
      line: 18,
    ),
    SonarQubeIssue(
      key: 'demo-2',
      type: 'VULNERABILITY',
      severity: 'MAJOR',
      message: 'Disable server certificate validation only in tests.',
      file: 'src/net/client.ts',
      line: 54,
    ),
    SonarQubeIssue(
      key: 'demo-3',
      type: 'BUG',
      severity: 'MAJOR',
      message: 'Handle the rejected promise returned by "save".',
      file: 'src/jobs/sync.ts',
      line: 102,
    ),
    SonarQubeIssue(
      key: 'demo-4',
      type: 'CODE_SMELL',
      severity: 'MINOR',
      message: 'Remove this unused import of "Fragment".',
      file: 'src/ui/queue.tsx',
      line: 3,
    ),
    SonarQubeIssue(
      key: 'demo-5',
      type: 'CODE_SMELL',
      severity: 'INFO',
      message: 'Complete the task associated with this TODO comment.',
      file: 'src/ui/history.tsx',
      line: 77,
    ),
  ];

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
    SonarQubeIssueGrouping grouping = SonarQubeIssueGrouping.none,
  }) async {
    if (projectKey != _bad || page > 1) {
      return const Ok(SonarQubeIssuePage(issues: [], total: 0));
    }
    final matching = [
      for (final issue in _issues)
        if ((filter.types.isEmpty || filter.types.contains(issue.type)) &&
            (filter.severities.isEmpty ||
                filter.severities.contains(issue.severity)))
          issue,
    ];
    return Ok(
      SonarQubeIssuePage(
        issues: matching,
        total: matching.length,
        groups: grouping.isGrouped
            ? [
                SonarQubeIssueGroup(
                  label: 'src/main.dart',
                  count: matching.length,
                ),
              ]
            : const [],
      ),
    );
  }

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async => Ok({
    for (final key in projectKeys)
      key: key == _bad
          ? const SonarQubeProjectSummary(
              gate: QualityGateState.failed,
              bugs: 3,
              vulnerabilities: 2,
              codeSmells: 57,
              coverage: 62.3,
            )
          : const SonarQubeProjectSummary(
              gate: QualityGateState.passed,
              bugs: 0,
              vulnerabilities: 0,
              codeSmells: 12,
              coverage: 91.4,
            ),
  });

  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) async {
    final line = issue.line ?? 1;
    return Ok(
      SonarQubeIssueContext(
        ruleName: switch (issue.type) {
          'VULNERABILITY' => 'Credentials should not be hard-coded',
          'BUG' => 'Promises should not be misused',
          _ => 'Unused imports should be removed',
        },
        snippet: [
          for (var n = line - 2; n <= line + 2; n++)
            if (n > 0)
              SonarQubeSourceLine(
                number: n,
                code: n == line
                    ? '  const value = loadSetting(); // flagged line'
                    : '  // sample code around the issue',
              ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) async => Ok([
    SonarQubeAnalysis(
      key: 'a3',
      date: _now.subtract(const Duration(hours: 5)),
      projectVersion: '1.8.2',
    ),
    SonarQubeAnalysis(
      key: 'a2',
      date: _now.subtract(const Duration(days: 3)),
      projectVersion: '1.8.1',
    ),
    SonarQubeAnalysis(
      key: 'a1',
      date: _now.subtract(const Duration(days: 9)),
      projectVersion: '1.8.0',
    ),
  ]);
}

@riverpod
DemoSonarQubeRepository demoSonarQubeRepository(Ref ref) {
  ref.watch(demoModeNotifierProvider);
  return DemoSonarQubeRepository();
}
