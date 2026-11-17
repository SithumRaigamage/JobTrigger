/// US-JX-22: does [secret] look like a Jenkins API token rather than an
/// account password? Legacy tokens are 32 hex characters. Current ones
/// are `11` followed by 32 hex characters, which the fixture's generated
/// tokens confirm. A heuristic run locally: the secret goes nowhere else.
///
/// A null [secret] (AUD-63: the backend could not decrypt it) is not a
/// token — and not a password either, so the caller must not describe it
/// as one.
bool looksLikeJenkinsApiToken(String? secret) =>
    secret != null && RegExp(r'^(11)?[0-9a-f]{32}$').hasMatch(secret.trim());

/// Where a user creates a token: their own configure page, which redirects
/// to the right place on every Jenkins version.
Uri jenkinsTokenPageUrl(String jenkinsUrl) {
  final base = jenkinsUrl.endsWith('/')
      ? jenkinsUrl.substring(0, jenkinsUrl.length - 1)
      : jenkinsUrl;
  return Uri.parse('$base/me/configure');
}

/// PI-09 / IMP-75: GitHub's token page, pre-filled with the classic scopes
/// this app needs (`repo` for private repositories, `workflow` to dispatch).
Uri gitHubTokenPageUrl() => Uri.parse(
  'https://github.com/settings/tokens/new'
  '?scopes=repo,workflow&description=JobTrigger',
);

/// PI-09 / IMP-75: SonarQube's user-token page. SonarCloud has its own
/// account-security page; a self-hosted Server nests it under the user.
Uri sonarQubeTokenPageUrl(String baseUrl) {
  final trimmed = baseUrl.trim();
  final base = trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
  final host = Uri.tryParse(base)?.host.toLowerCase() ?? '';
  if (host == 'sonarcloud.io' || host.endsWith('.sonarcloud.io')) {
    return Uri.parse('https://sonarcloud.io/account/security');
  }
  return Uri.parse('$base/user/account/security');
}
