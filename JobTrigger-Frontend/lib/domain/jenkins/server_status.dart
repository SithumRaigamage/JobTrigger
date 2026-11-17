/// The active Jenkins' version and shutdown state (US-JX-18).
class ServerStatus {
  const ServerStatus({this.version, this.quietingDown = false});

  /// From the `X-Jenkins` response header, e.g. `2.568.3`.
  final String? version;

  /// "Prepare for shutdown" is on. Triggers are still accepted (201,
  /// verified), but queued builds won't start until it's cancelled.
  final bool quietingDown;
}

/// Compares dotted Jenkins versions numerically (`2.568.3` > `2.99`).
/// Non-numeric parts (e.g. `-SNAPSHOT`) are ignored.
int compareJenkinsVersions(String a, String b) {
  List<int> parts(String version) => [
    for (final part in version.split('.'))
      int.tryParse(part.replaceAll(RegExp(r'[^0-9].*$'), '')) ?? 0,
  ];
  final left = parts(a);
  final right = parts(b);
  for (var i = 0; i < left.length || i < right.length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

/// Older than [baseline]: informational only, never blocking (US-JX-18).
bool isOutdatedJenkins(String version, String baseline) =>
    compareJenkinsVersions(version, baseline) < 0;
