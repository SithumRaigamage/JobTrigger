import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'jenkins_build.dart';
import 'jenkins_job.dart';
import 'log_chunk.dart';

abstract class JenkinsRepository {
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree();

  /// [jobUrl] is the job's already-rewritten absolute URL (from a
  /// previously-fetched tree), not a relative path.
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl);

  /// [buildUrl] is the build's already-rewritten absolute URL. [start] is
  /// the byte offset to resume from (0 for the first read).
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  });

  /// Last 20 builds for one job (per-job history, P5-16) — a separate
  /// fetch from [fetchJobDetail], per `JenkinsAPIService.fetchBuildHistory`
  /// (Swift).
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(String jobUrl);

  /// POSTs `build` (no params) or `buildWithParameters` (form-urlencoded),
  /// chosen the same way as `JenkinsAPIService.triggerJob` (Swift): use
  /// `buildWithParameters` if the job itself is parameterized OR
  /// [parameters] is non-empty. [paramToken] is appended as `?token=` when
  /// present, matching a Jenkins server configured to require it.
  Future<Result<void, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  });

  /// POSTs `{buildNumber}/stop` — [buildUrl] is the build's absolute URL
  /// (e.g. `.../job/x/20/`).
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl);
}
