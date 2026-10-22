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
    this.needsReentry = false,
  });

  final String id;
  final String serverName;
  final String jenkinsURL;
  final String username;

  /// The stored secret, or null when the backend could not decrypt it
  /// (AUD-63). A null secret is not "no password" — it means the
  /// credential is listed but unusable until the user types the secret
  /// again, so nothing may be sent to Jenkins in its place.
  final String? secret;
  final String? paramToken;
  final bool isDefault;

  /// AUD-63: the backend flags a credential whose secret it could not
  /// decrypt. The app still lists it (one unreadable secret must not
  /// fail the whole list) and asks the user to re-enter the secret.
  final bool needsReentry;

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
      other.isDefault == isDefault &&
      other.needsReentry == needsReentry;

  @override
  int get hashCode => Object.hash(
    id,
    serverName,
    jenkinsURL,
    username,
    secret,
    paramToken,
    isDefault,
    needsReentry,
  );
}
