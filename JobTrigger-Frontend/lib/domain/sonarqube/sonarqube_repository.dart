import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
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
}

/// `ps` for `api/projects/search`; 500 is SonarQube's maximum.
const sonarQubeProjectsPageSize = 500;
