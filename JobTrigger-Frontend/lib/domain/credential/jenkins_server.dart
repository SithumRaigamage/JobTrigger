/// Ported from `JenkinsCredentials.swift` / the backend's `JenkinsCredential`
/// model. Domain-side, the raw `password` field is renamed `secret` so call
/// sites can't miss that it's sensitive — see `docs/data-models.md`.
class JenkinsServer {
  const JenkinsServer({
    required this.id,
    required this.serverName,
    required this.jenkinsURL,
    required this.username,
    required this.secret,
    this.paramToken,
    this.isDefault = false,
  });

  final String id;
  final String serverName;
  final String jenkinsURL;
  final String username;
  final String secret;
  final String? paramToken;
  final bool isDefault;

  /// Redacted — `secret` must never end up in logs or crash reports.
  @override
  String toString() =>
      'JenkinsServer(id: $id, serverName: $serverName, jenkinsURL: $jenkinsURL, '
      'username: $username, secret: ***, paramToken: '
      '${paramToken == null ? 'null' : '***'}, isDefault: $isDefault)';

  /// Value equality, so a reload that changed nothing doesn't rebuild the
  /// client built from this entry (AUD-46).
  @override
  bool operator ==(Object other) =>
      other is JenkinsServer &&
      other.id == id &&
      other.serverName == serverName &&
      other.jenkinsURL == jenkinsURL &&
      other.username == username &&
      other.secret == secret &&
      other.paramToken == paramToken &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(
    id,
    serverName,
    jenkinsURL,
    username,
    secret,
    paramToken,
    isDefault,
  );
}
