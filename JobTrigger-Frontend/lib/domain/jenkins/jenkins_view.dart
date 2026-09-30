/// A Jenkins view: a named subset of jobs (US-JX-17).
class JenkinsView {
  const JenkinsView({
    required this.name,
    required this.url,
    this.isPrimary = false,
  });

  final String name;

  /// Rewritten to the active server. The primary view's URL is the server
  /// root (verified), so listing it is the same as the plain root listing.
  final String url;

  /// The server's default view, usually "all".
  final bool isPrimary;

  /// "all" reads better as "All jobs".
  String get label => isPrimary && name == 'all' ? 'All jobs' : name;
}
