import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../domain/sonarqube/sonarqube_analysis.dart';
import '../../domain/sonarqube/sonarqube_issue.dart';
import '../../domain/sonarqube/sonarqube_project.dart';
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
    return Ok(SonarQubeIssuePage(issues: matching, total: matching.length));
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
