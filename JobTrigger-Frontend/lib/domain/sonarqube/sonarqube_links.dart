import '../credential/server_url.dart';

/// Where a project, or one issue in it, lives in SonarQube's own web UI, for
/// "Open in SonarQube" (`US-SQ-LINK-01`). [baseUrl] is the credential's
/// instance URL; one with a path (a server behind `/sonar`) keeps it.
Uri sonarQubeProjectUri(String baseUrl, String projectKey) =>
    _under(baseUrl, '/dashboard', {'id': projectKey});

Uri sonarQubeIssueUri(String baseUrl, String projectKey, String issueKey) =>
    _under(baseUrl, '/project/issues', {
      'id': projectKey,
      'issues': issueKey,
      'open': issueKey,
    });

Uri _under(String baseUrl, String path, Map<String, String> query) {
  final base = Uri.parse(normalizeServerUrl(baseUrl));
  // A saved URL never has a query or fragment (`sonarQubeUrlProblem`), so
  // only the path and query need setting.
  return base.replace(path: '${base.path}$path', queryParameters: query);
}
