import '../../domain/jenkins/downstream_project.dart';
import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';
import '../../domain/jenkins/upstream_cause.dart';

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
  downstreamProjects: job.downstreamProjects
      .map(
        (d) =>
            DownstreamProject(name: d.name, url: _rewriteUrl(d.url, activeUri)),
      )
      .toList(),
);

JenkinsBuild _rewriteBuild(JenkinsBuild build, Uri activeUri) => build.copyWith(
  url: _rewriteUrl(build.url, activeUri),
  upstreamCause: build.upstreamCause == null
      ? null
      : UpstreamCause(
          projectName: build.upstreamCause!.projectName,
          url: _rewriteUrl(build.upstreamCause!.url, activeUri),
        ),
);

/// Rewrites a single Jenkins-origin URL that doesn't come from a
/// `JenkinsJob`/`JenkinsBuild` payload — e.g. a trigger response's
/// `Location` header pointing at a queue item (US-PIPE-01). Same
/// scheme/host/port substitution as the tree/build rewrite above.
String rewriteUrl(String rawUrl, String activeServerUrl) =>
    _rewriteUrl(rawUrl, Uri.parse(activeServerUrl));

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
