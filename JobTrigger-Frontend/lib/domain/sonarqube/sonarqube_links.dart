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

/// `jobtrigger://app/sonarqube/project?key=KEY` (`US-SQ-LINK-02`): opens a
/// project in the app. It carries the project key and nothing else — no
/// server, no token — so a link can never point the app at a different host
/// or smuggle a credential in: the project is looked up on the credential
/// the user already has.
Uri sonarQubeAppLink(String projectKey) => Uri(
  scheme: 'jobtrigger',
  host: 'app',
  path: '/sonarqube/project',
  queryParameters: {'key': projectKey},
);

/// Whether [key] can be a project key from a link: SonarQube allows letters,
/// digits and `-_.:`, at most 400 characters. Anything else (empty, spaces,
/// control characters, a URL) is refused before any request is made.
bool sonarQubeLinkKeyIsValid(String? key) =>
    key != null &&
    key.isNotEmpty &&
    key.length <= 400 &&
    RegExp(r'^[A-Za-z0-9_.:\-]+$').hasMatch(key);

/// The text Copy and Share send for an issue (`US-SQ-ISSUES-04`): what it is,
/// where, which rule, and the web link from `US-SQ-LINK-01`. Built from the
/// issue's own fields only — never a token, and the link is the plain web
/// address, which carries none.
String sonarQubeIssueShareText({
  required String projectName,
  required String message,
  required String severityLabel,
  required String typeLabel,
  required Uri link,
  String? rule,
  String? ruleName,
  String? location,
}) {
  final ruleLine = rule == null
      ? null
      : (ruleName == null || ruleName.isEmpty ? rule : '$rule — $ruleName');
  return [
    message,
    '$typeLabel · $severityLabel · $projectName',
    if (location != null) 'Where: $location',
    ?(ruleLine == null ? null : 'Rule: $ruleLine'),
    link.toString(),
  ].join('\n');
}
