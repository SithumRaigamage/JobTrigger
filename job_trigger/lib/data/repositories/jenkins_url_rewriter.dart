import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';

/// Jenkins returns absolute `url` fields using whatever host it was
/// configured with internally, which breaks when reached via a different
/// external host or a tunnel — see `docs/architecture.md §5`. Rewrites the
/// scheme/host/port of every `url` in the tree (jobs, nested jobs,
/// `lastBuild`, `builds[]`) to match [activeServerUrl], preserving path and
/// query. A pure function, deliberately separate from `JenkinsRepositoryImpl`
/// so it's unit-testable in isolation without a `Dio`/`ProviderContainer`.
List<JenkinsJob> rewriteJobTreeUrls(
  List<JenkinsJob> jobs,
  String activeServerUrl,
) {
  final activeUri = Uri.parse(activeServerUrl);
  return jobs.map((job) => _rewriteJob(job, activeUri)).toList();
}

/// Same rewrite, for a standalone build list (e.g. per-job history, which
/// isn't nested inside a `JenkinsJob`).
List<JenkinsBuild> rewriteBuildUrls(
  List<JenkinsBuild> builds,
  String activeServerUrl,
) {
  final activeUri = Uri.parse(activeServerUrl);
  return builds.map((build) => _rewriteBuild(build, activeUri)).toList();
}

JenkinsJob _rewriteJob(JenkinsJob job, Uri activeUri) => JenkinsJob(
  name: job.name,
  url: _rewriteUrl(job.url, activeUri),
  description: job.description,
  color: job.color,
  jobs: job.jobs?.map((child) => _rewriteJob(child, activeUri)).toList(),
  lastBuild: job.lastBuild == null
      ? null
      : _rewriteBuild(job.lastBuild!, activeUri),
  healthReport: job.healthReport,
  property: job.property,
  builds: job.builds.map((build) => _rewriteBuild(build, activeUri)).toList(),
);

JenkinsBuild _rewriteBuild(JenkinsBuild build, Uri activeUri) => JenkinsBuild(
  number: build.number,
  url: _rewriteUrl(build.url, activeUri),
  result: build.result,
  timestamp: build.timestamp,
  duration: build.duration,
  estimatedDuration: build.estimatedDuration,
  building: build.building,
  displayName: build.displayName,
);

String _rewriteUrl(String rawUrl, Uri activeUri) {
  final parsed = Uri.tryParse(rawUrl);
  if (parsed == null) return rawUrl;
  return parsed
      .replace(
        scheme: activeUri.scheme,
        host: activeUri.host,
        port: activeUri.hasPort ? activeUri.port : null,
      )
      .toString();
}
