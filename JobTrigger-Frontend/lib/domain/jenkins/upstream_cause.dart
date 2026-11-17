/// The upstream job/build that triggered this one (US-PIPE-09), when the
/// build's cause was an upstream project rather than a person/timer/SCM
/// hook. [url] is the upstream job's URL (not the specific build) — same
/// Jenkins-origin absolute URL every other `url` field is, needs the same
/// scheme/host/port rewrite (`jenkins_url_rewriter.dart`).
class UpstreamCause {
  const UpstreamCause({required this.projectName, required this.url});

  final String projectName;
  final String url;
}
