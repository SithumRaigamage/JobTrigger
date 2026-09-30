/// AUD-14: what counts as a usable Jenkins URL.
///
/// Plain `http://` is allowed (P12-06, decided 2026-09-30: LAN Jenkins
/// servers are common) but flagged, because Basic Auth then sends the
/// username and password or token unencrypted. The app's HTTP stack
/// (`dart:io`) isn't subject to iOS App Transport Security or Android's
/// cleartext policy, so there's no platform block to explain; the warning
/// is the whole mitigation.
library;

/// The URL trimmed and without trailing slashes, which the repository adds
/// back where a path needs one.
String normalizeJenkinsUrl(String raw) =>
    raw.trim().replaceFirst(RegExp(r'/+$'), '');

/// Why [raw] can't be used, or null when it can.
String? jenkinsUrlProblem(String raw) {
  final value = normalizeJenkinsUrl(raw);
  if (value.isEmpty) return 'Enter the Jenkins URL.';
  final uri = Uri.tryParse(value);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return 'The URL must start with https:// (or http://).';
  }
  if (uri.host.isEmpty) {
    return 'The URL needs a host name, e.g. ci.example.com.';
  }
  if (uri.hasQuery || uri.hasFragment) {
    return 'Use the Jenkins address only, without ? or # parts.';
  }
  return null;
}

/// True for `http://`, where credentials travel unencrypted.
bool isCleartextUrl(String raw) =>
    Uri.tryParse(normalizeJenkinsUrl(raw))?.isScheme('http') ?? false;
