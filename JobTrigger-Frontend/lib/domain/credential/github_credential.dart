/// Mirrors `JobTrigger-Backend/models/GitHubCredential.js`. Domain-side,
/// the raw `token` field is renamed `secret` so call sites can't miss
/// that it's sensitive — same convention as `JenkinsServer.secret`.
class GitHubCredential {
  const GitHubCredential({
    required this.id,
    required this.label,
    required this.secret,
    this.defaultOwner,
    this.isDefault = false,
    this.needsReentry = false,
  });

  final String id;
  final String label;

  /// The stored token, or null when the backend could not decrypt it
  /// (AUD-63). A null token is not "no token" — it means the credential
  /// is listed but unusable until the user types it again, so nothing may
  /// be sent to GitHub in its place.
  final String? secret; // GitHub Personal Access Token
  final String? defaultOwner;
  final bool isDefault;

  /// AUD-63: the backend flags a credential whose token it could not
  /// decrypt. The app still lists it (one unreadable secret must not
  /// fail the whole list) and asks the user to re-enter the token.
  final bool needsReentry;

  /// Redacted — `secret` must never end up in logs or crash reports.
  @override
  String toString() =>
      'GitHubCredential(id: $id, label: $label, secret: ***, '
      'defaultOwner: $defaultOwner, isDefault: $isDefault)';

  /// Value equality, so a reload that changed nothing doesn't rebuild the
  /// client built from this entry (AUD-46).
  @override
  bool operator ==(Object other) =>
      other is GitHubCredential &&
      other.id == id &&
      other.label == label &&
      other.secret == secret &&
      other.defaultOwner == defaultOwner &&
      other.isDefault == isDefault &&
      other.needsReentry == needsReentry;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    secret,
    defaultOwner,
    isDefault,
    needsReentry,
  );
}
