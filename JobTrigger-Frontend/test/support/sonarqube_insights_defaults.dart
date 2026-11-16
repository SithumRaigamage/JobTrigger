import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis_status.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_hotspot.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_branch_ref.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_history.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_worst_files.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_delta.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_metrics.dart';

/// Empty answers for the batch-1 SonarQube reads (P10-18: `US-SQ-ISSUES-01`,
/// `US-SQ-CE-01`, `US-SQ-QUALITY-08/09`), so a test fake implements only the
/// calls its test drives instead of repeating four stubs.
///
/// It lives in `test/` on purpose: only a test may answer "no issues, no
/// scan, no new code" — production code goes through
/// `SonarQubeRepositoryImpl`, where all four ask the server.
mixin SonarQubeInsightsDefaults {
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchMyIssues({
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) async => const Ok(SonarQubeIssuePage(issues: [], total: 0));

  Future<Result<SonarQubeAnalysisStatus, AppFailure>> fetchAnalysisStatus(
    String projectKey,
  ) async => const Ok(SonarQubeAnalysisStatus.none);

  Future<Result<Map<String, String>, AppFailure>> fetchNewCodeMeasures(
    String projectKey,
  ) async => const Ok({});

  Future<Result<SonarQubeRefChoices, AppFailure>> fetchProjectRefs(
    String projectKey,
  ) async => const Ok(SonarQubeRefChoices.none);

  Future<Result<SonarQubeWorstFiles, AppFailure>> fetchWorstFiles(
    String projectKey,
    SonarQubeFileMetric metric,
  ) async => Ok(SonarQubeWorstFiles(metric: metric.metric, files: const []));

  Future<Result<SonarQubeIssuePage, AppFailure>> fetchFileIssues(
    String componentKey,
  ) async => const Ok(SonarQubeIssuePage(issues: [], total: 0));

  Future<Result<SonarQubeMeasureHistory, AppFailure>> fetchMeasureHistory(
    String projectKey,
    String metric,
  ) async => Ok(SonarQubeMeasureHistory(metric: metric, points: const []));

  Future<Result<SonarQubeHotspotPage, AppFailure>> fetchHotspots(
    String projectKey, {
    bool reviewed = false,
    int page = 1,
  }) async => const Ok(SonarQubeHotspotPage(hotspots: [], total: 0));

  Future<Result<SonarQubeHotspotDetail, AppFailure>> fetchHotspotDetail(
    String hotspotKey,
  ) async => const Ok(SonarQubeHotspotDetail());

  Future<Result<List<SonarQubeMeasureDelta>, AppFailure>> fetchMeasureDeltas(
    String projectKey, {
    List<String> metricKeys = sonarQubeMeasureKeys,
  }) async => const Ok([]);
}
