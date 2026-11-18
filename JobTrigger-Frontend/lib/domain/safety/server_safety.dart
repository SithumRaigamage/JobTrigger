/// Local-only safety preferences (PI-01/IMP-25, PI-02/IMP-24).
///
/// These are deliberately client-side settings on this device, not credential
/// fields. Credentials are owned by the backend (Mongoose → DTO → domain), so
/// a read-only/protected flag here needs no backend or DTO change and keeps
/// the 1.0 credential models frozen. Nothing in here is secret or leaves the
/// phone.
class ServerSafety {
  const ServerSafety({
    this.readOnly = const <String>{},
    this.protectedJobs = const <String>{},
  });

  factory ServerSafety.fromJson(Map<String, dynamic> json) => ServerSafety(
    readOnly: _stringSet(json['readOnly']),
    protectedJobs: _stringSet(json['protectedJobs']),
  );

  /// Credential keys in the form `<tool.key>:<credentialId>`.
  final Set<String> readOnly;

  /// Protected job keys in the form `<tool.key>:<normalised job key>`.
  final Set<String> protectedJobs;

  Map<String, dynamic> toJson() => {
    'readOnly': readOnly.toList()..sort(),
    'protectedJobs': protectedJobs.toList()..sort(),
  };

  bool isReadOnly(SafetyTool tool, String credentialId) =>
      readOnly.contains('${tool.key}:$credentialId');

  bool isProtected(SafetyTool tool, String jobKey) =>
      protectedJobs.contains('${tool.key}:${normaliseJobKey(jobKey)}');

  ServerSafety withReadOnly(SafetyTool tool, String credentialId, bool value) {
    final next = Set<String>.from(readOnly);
    final key = '${tool.key}:$credentialId';
    if (value) {
      next.add(key);
    } else {
      next.remove(key);
    }
    return ServerSafety(readOnly: next, protectedJobs: protectedJobs);
  }

  ServerSafety withProtected(SafetyTool tool, String jobKey, bool value) {
    final next = Set<String>.from(protectedJobs);
    final key = '${tool.key}:${normaliseJobKey(jobKey)}';
    if (value) {
      next.add(key);
    } else {
      next.remove(key);
    }
    return ServerSafety(readOnly: readOnly, protectedJobs: next);
  }

  /// Strip incidental whitespace and trailing slashes so the same job does
  /// not get two protected markers. Case is preserved: Jenkins job names are
  /// case-sensitive, so lowercasing could merge two different jobs.
  static String normaliseJobKey(String key) {
    var value = key.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static Set<String> _stringSet(Object? raw) =>
      raw is List ? raw.whereType<String>().toSet() : const <String>{};

  @override
  bool operator ==(Object other) =>
      other is ServerSafety &&
      _sameSet(readOnly, other.readOnly) &&
      _sameSet(protectedJobs, other.protectedJobs);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(readOnly),
    Object.hashAllUnordered(protectedJobs),
  );

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// The three tools with write actions in 1.0. [key] is stored in prefs — keep
/// the values stable across releases.
enum SafetyTool {
  jenkins('jenkins'),
  githubActions('githubActions'),
  sonarqube('sonarqube');

  const SafetyTool(this.key);
  final String key;
}
