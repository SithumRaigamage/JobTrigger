/// What the server says about itself (`US-SQ-SERVER-01`): `api/server/version`
/// answers a bare version string, `api/system/status` a state such as `UP`.
class SonarQubeServerInfo {
  const SonarQubeServerInfo({required this.version, required this.status});

  final String version;
  final String status;

  bool get isUp => status.toUpperCase() == 'UP';

  /// The server's own word, made readable: `UP` → "Up".
  String get statusLabel {
    if (status.isEmpty) return 'Unknown';
    final lower = status.toLowerCase().replaceAll('_', ' ');
    return lower[0].toUpperCase() + lower.substring(1);
  }

  /// Readable when the server starts but is still migrating, which is the
  /// common confusing case.
  String get hint => switch (status.toUpperCase()) {
    'UP' => '',
    'STARTING' => 'The server is starting; results may be incomplete.',
    'MAINTENANCE' => 'The server is in maintenance mode.',
    _ => 'The server reported "$status".',
  };
}
