/// P25-05: the optional context attached to a report, shown to the user
/// before it is sent. Built from values the app already has, and deliberately
/// small: version/build, the tool in use, the platform, and the active
/// server's scheme+host+port. Never a job path, query string, username or
/// credential — see `hostOnly`.
class SupportDiagnostics {
  const SupportDiagnostics({
    required this.appVersion,
    required this.buildNumber,
    required this.tool,
    required this.platform,
    this.serverHost,
  });

  final String appVersion;
  final String buildNumber;
  final String tool;
  final String platform;
  final String? serverHost;

  Map<String, Object?> toJson() => {
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'tool': tool,
    'platform': platform,
    if (serverHost != null) 'serverHost': serverHost,
  };

  /// "1.0.0 (7) · jenkins · ios · https://ci.example.com" — the line the
  /// form shows when diagnostics are attached.
  String get summary => [
    if (appVersion.isNotEmpty) 'Version $appVersion ($buildNumber)',
    tool,
    platform,
    ?serverHost,
  ].join(' · ');
}

/// scheme://host[:port] from [url], or null. Drops the path, query, fragment
/// and any `user:pass@`, so a stored server can never carry a job name or a
/// secret into a ticket.
String? hostOnly(String? url) {
  final uri = url == null ? null : Uri.tryParse(url.trim());
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return null;
  }
  if (uri.host.isEmpty) return null;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}
