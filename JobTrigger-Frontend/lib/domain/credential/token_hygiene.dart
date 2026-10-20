/// US-JX-22: does [secret] look like a Jenkins API token rather than an
/// account password? Legacy tokens are 32 hex characters. Current ones
/// are `11` followed by 32 hex characters, which the fixture's generated
/// tokens confirm. A heuristic run locally: the secret goes nowhere else.
bool looksLikeJenkinsApiToken(String secret) =>
    RegExp(r'^(11)?[0-9a-f]{32}$').hasMatch(secret.trim());

/// Where a user creates a token: their own configure page, which redirects
/// to the right place on every Jenkins version.
Uri jenkinsTokenPageUrl(String jenkinsUrl) {
  final base = jenkinsUrl.endsWith('/')
      ? jenkinsUrl.substring(0, jenkinsUrl.length - 1)
      : jenkinsUrl;
  return Uri.parse('$base/me/configure');
}
