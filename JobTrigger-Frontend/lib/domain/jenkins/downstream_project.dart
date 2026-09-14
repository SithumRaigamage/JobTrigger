/// A job this job triggers (US-PIPE-09) — Jenkins' `downstreamProjects`.
class DownstreamProject {
  const DownstreamProject({required this.name, required this.url});

  final String name;
  final String url;
}
