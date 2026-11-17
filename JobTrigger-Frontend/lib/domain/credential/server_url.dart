/// AUD-14 / AUD-52: what counts as a usable server URL for any credential
/// whose secret the app sends to that server itself (Jenkins Basic Auth, a
/// SonarQube Bearer token).
///
/// Plain `http://` is allowed (P12-06, decided 2026-09-30: LAN servers are
/// common) but flagged, because the secret then travels unencrypted. The
/// app's HTTP stack (`dart:io`) isn't subject to iOS App Transport Security
/// or Android's cleartext policy, so there's no platform block to explain;
/// the warning is the whole mitigation.
library;

/// The URL trimmed and without trailing slashes, which the repositories add
/// back where a path needs one.
String normalizeServerUrl(String raw) =>
    raw.trim().replaceFirst(RegExp(r'/+$'), '');

/// Why [raw] can't be used as the address of a [product] server ("Jenkins",
/// "SonarQube"), or null when it can.
String? serverUrlProblem(String raw, {required String product}) {
  final value = normalizeServerUrl(raw);
  if (value.isEmpty) return 'Enter the $product URL.';
  final uri = Uri.tryParse(value);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return 'The URL must start with https:// (or http://).';
  }
  if (uri.host.isEmpty) {
    return 'The URL needs a host name, e.g. ci.example.com.';
  }
  if (uri.hasQuery || uri.hasFragment) {
    return 'Use the $product address only, without ? or # parts.';
  }
  return null;
}

/// True for `http://`, where credentials travel unencrypted.
bool isCleartextUrl(String raw) =>
    Uri.tryParse(normalizeServerUrl(raw))?.isScheme('http') ?? false;
