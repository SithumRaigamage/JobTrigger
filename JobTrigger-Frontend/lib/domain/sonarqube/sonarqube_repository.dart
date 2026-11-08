import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'sonarqube_analysis.dart';
import 'sonarqube_issue.dart';
import 'sonarqube_project.dart';
import 'sonarqube_quality_gate.dart';

/// SonarQube data access — independent of the Jenkins and GitHub
/// repositories (`NFR-SEC-03`). Read-only by design: SonarQube here is a
/// code-quality viewer, with nothing to trigger or cancel. Grown one method
/// per SQ task, as `GitHubRepository` was.
abstract class SonarQubeRepository {
  /// `GET api/projects/search` (`US-SQ-PROJ-01`). Sends `organization` when
  /// the active credential has one (SonarCloud); self-hosted servers don't.
  /// A SonarCloud organization key that doesn't exist comes back as
  /// [SonarQubeOrganizationNotFoundFailure], distinct from a generic 404.
  /// First page only ([sonarQubeProjectsPageSize], the API's maximum).
  Future<Result<List<SonarQubeProject>, AppFailure>> fetchProjects();

  /// `GET api/qualitygates/project_status?projectKey=` (`US-SQ-QUALITY-01`).
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  );

  /// `GET api/measures/component` for `sonarQubeMeasureKeys`
  /// (`US-SQ-QUALITY-02`). Keyed by metric; a metric the server didn't
  /// compute is simply absent, so the UI can show "—" rather than 0.
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  );

  /// `GET api/issues/search` (`US-SQ-QUALITY-03`), unresolved issues only,
  /// filtered and paged by the server. [page] is 1-based;
  /// [sonarQubeIssuesPageSize] per page. SonarQube refuses to page past
  /// 10,000 results, so the list ends there however large [total] is.
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  });

  /// `GET api/project_analyses/search?project=` (`US-SQ-QUALITY-04`): the
  /// latest [sonarQubeAnalysesLimit] analyses, newest first.
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  );
}

/// `ps` for `api/projects/search`; 500 is SonarQube's maximum.
const sonarQubeProjectsPageSize = 500;
