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
  });

  final String id;
  final String label;
  final String secret; // GitHub Personal Access Token
  final String? defaultOwner;
  final bool isDefault;

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
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(id, label, secret, defaultOwner, isDefault);
}
