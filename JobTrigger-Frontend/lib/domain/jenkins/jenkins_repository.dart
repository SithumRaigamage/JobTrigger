import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'jenkins_build.dart';
import 'jenkins_job.dart';
import 'log_chunk.dart';
import 'queue_item.dart';
import 'test_report.dart';

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
  ///
  /// Returns the rewritten queue-item URL from the response's `Location`
  /// header on success (US-PIPE-01), or `null` if Jenkins didn't send one
  /// — triggering still succeeded either way; a missing/unparseable
  /// `Location` only means this specific build can't be tracked through
  /// the queue, not that the request failed.
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  });

  /// POSTs `{buildNumber}/stop` — [buildUrl] is the build's absolute URL
  /// (e.g. `.../job/x/20/`).
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl);

  /// `GET {queueItemUrl}api/json` (US-PIPE-01) — [queueItemUrl] is the
  /// already-rewritten URL returned by [triggerBuild]. Jenkins' queue is
  /// server-wide with no per-job endpoint, so this only tracks a specific
  /// item already known by URL, not "is this job currently queued."
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(String queueItemUrl);

  /// `GET {buildUrl}testReport/api/json` (US-PIPE-06). Returns `Ok(null)`
  /// (not an [Err]) when the build has no published test report — a
  /// normal state (the job doesn't publish test results, or this build
  /// hasn't finished), surfaced as a real 404 from Jenkins.
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String buildUrl);
}
