import '../../domain/jenkins/downstream_project.dart';
import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';
import '../../domain/jenkins/queue_item.dart';
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

/// Rewrites a queue item's `executable.url` (US-PIPE-01) -- the one
/// Jenkins-origin URL `JenkinsRepositoryImpl.fetchQueueItem` previously left
/// unrewritten, unlike every other job/build URL in the app.
QueueItem rewriteQueueItemUrl(QueueItem item, String activeServerUrl) {
  final executable = item.executable;
  if (executable == null) return item;
  return QueueItem(
    why: item.why,
    cancelled: item.cancelled,
    executable: QueueExecutable(
      number: executable.number,
      url: _rewriteUrl(executable.url, Uri.parse(activeServerUrl)),
    ),
  );
}

/// Rewrites a single Jenkins-origin URL that doesn't come from a
/// `JenkinsJob`/`JenkinsBuild` payload — e.g. a trigger response's
/// `Location` header pointing at a queue item (US-PIPE-01). Same
/// scheme/host/port substitution as the tree/build rewrite above.
String rewriteUrl(String rawUrl, String activeServerUrl) =>
    _rewriteUrl(rawUrl, Uri.parse(activeServerUrl));

String _rewriteUrl(String rawUrl, Uri activeUri) {
  final parsed = Uri.tryParse(rawUrl);
  if (parsed == null) return rawUrl;
  // Uri.replace treats a null argument as "leave unchanged," not "clear" --
  // passing port: null when activeUri has no explicit port would silently
  // keep the raw URL's own port instead of dropping it. Route through
  // Uri.replace(port:) only when there's an explicit port to set, and
  // Uri(...) otherwise so the scheme's default port applies.
  return (activeUri.hasPort
          ? parsed.replace(
              scheme: activeUri.scheme,
              host: activeUri.host,
              port: activeUri.port,
            )
          : Uri(
              scheme: activeUri.scheme,
              host: activeUri.host,
              path: parsed.path,
              query: parsed.query.isEmpty ? null : parsed.query,
              fragment: parsed.fragment.isEmpty ? null : parsed.fragment,
            ))
      .toString();
}
