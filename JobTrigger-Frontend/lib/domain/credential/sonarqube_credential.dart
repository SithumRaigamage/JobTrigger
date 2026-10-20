/// Mirrors `JobTrigger-Backend/models/SonarQubeCredential.js`. Domain-side,
/// the raw `token` field is renamed `secret` so call sites can't miss
/// that it's sensitive — same convention as `JenkinsServer.secret`/
/// `GitHubCredential.secret`.
class SonarQubeCredential {
  const SonarQubeCredential({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.secret,
    this.defaultOrganization,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String baseUrl; // SonarCloud or a self-hosted SonarQube Server
  final String secret; // SonarQube User Token
  final String? defaultOrganization;
  final bool isDefault;

  /// Redacted — `secret` must never end up in logs or crash reports.
  @override
  String toString() =>
      'SonarQubeCredential(id: $id, label: $label, baseUrl: $baseUrl, '
      'secret: ***, defaultOrganization: $defaultOrganization, '
      'isDefault: $isDefault)';

  /// Value equality, so a reload that changed nothing doesn't rebuild the
  /// client built from this entry (AUD-46).
  @override
  bool operator ==(Object other) =>
      other is SonarQubeCredential &&
      other.id == id &&
      other.label == label &&
      other.baseUrl == baseUrl &&
      other.secret == secret &&
      other.defaultOrganization == defaultOrganization &&
      other.isDefault == isDefault;

  @override
  int get hashCode =>
      Object.hash(id, label, baseUrl, secret, defaultOrganization, isDefault);
}
