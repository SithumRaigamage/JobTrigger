import '../../core/error/app_failure.dart';

/// PI-03 / IMP-35: the structured answer to "why can't I reach it?".
///
/// This is deliberately pure and *heuristic*: it has no connectivity plugin
/// and never claims to know which network the phone is on. A private address
/// or Tailscale address in the saved URL is a strong hint, so the copy says
/// "if you're away from home" / "if Tailscale is off" rather than asserting
/// it as a detected fact.

/// The in-depth guide that explains a cause, when there is one.
enum ConnectionGuide { remoteAccess }

/// The five common causes, plus a fallback for everything else.
enum ConnectionCause {
  wrongUrl,
  privateAddress,
  vpnOff,
  certificate,
  network,
  other,
}

/// One diagnosis: a short [title], a plain-language [explanation], concrete
/// [fixTips], and an optional [guide] for the full walkthrough.
class ConnectionDiagnosis {
  const ConnectionDiagnosis({
    required this.cause,
    required this.title,
    required this.explanation,
    required this.fixTips,
    this.guide,
  });

  final ConnectionCause cause;
  final String title;
  final String explanation;
  final List<String> fixTips;
  final ConnectionGuide? guide;
}

/// Turns a saved [url] and the [failure] a request produced into advice.
ConnectionDiagnosis diagnoseConnection(String url, AppFailure failure) {
  final uri = Uri.tryParse(url);
  // A URL that isn't even parseable (or has no host) is the one case where
  // "wrong address" is certain rather than a hint (IMP-35).
  if (uri == null || uri.host.isEmpty) return _wrongUrl();

  final host = uri.host.toLowerCase();
  final ipv4 = _ipv4(host);

  if (failure is BadCertificateFailure) return _certificate(host);
  if (failure is NotFoundFailure || failure is UnexpectedResponseFailure) {
    return _wrongUrl();
  }
  if (failure.isUnreachable) {
    if (ipv4 != null && ipv4[0] == 100 && ipv4[1] >= 64 && ipv4[1] <= 127) {
      return _vpnOff(host); // 100.64.0.0/10 is the Tailscale/CGNAT range.
    }
    if (_isPrivate(ipv4) || host == 'localhost' || host.endsWith('.local')) {
      return _privateAddress(host);
    }
    return _network(host);
  }
  return _other();
}

/// The canonical scenarios, in guide order. The help screen renders these
/// so the pure diagnosis is the single source of its copy.
List<ConnectionDiagnosis> connectionChecklist() => [
  diagnoseConnection(
    'https://ci.example.com/jenkins/',
    const NotFoundFailure(),
  ),
  diagnoseConnection('http://192.168.1.24:8080', const NetworkFailure()),
  diagnoseConnection('http://100.101.102.103:8080', const NetworkFailure()),
  diagnoseConnection('https://ci.example.com', const BadCertificateFailure()),
  diagnoseConnection('https://ci.example.com', const NetworkFailure()),
];

ConnectionDiagnosis _wrongUrl() => const ConnectionDiagnosis(
  cause: ConnectionCause.wrongUrl,
  title: 'The address may be wrong',
  explanation:
      'The server answered, but not with what the app expected — often a '
      'login or proxy page. The saved URL has to point at Jenkins itself.',
  fixTips: [
    'Open the saved address in Safari to see what answers.',
    'Edit the server URL in Settings, without a trailing /job/… path.',
    'If Safari shows a sign-in page, use that page’s address as the server URL.',
  ],
);

ConnectionDiagnosis _privateAddress(String host) => ConnectionDiagnosis(
  cause: ConnectionCause.privateAddress,
  title: 'A private address only works at home',
  explanation:
      '$host is a private address. If the phone is on mobile data or another '
      'Wi-Fi, that address doesn’t exist — it belongs to your home network.',
  fixTips: [
    'Try again on the same Wi-Fi as the computer running Jenkins.',
    'For use anywhere, set up Tailscale or WireGuard (see the guide).',
    'Keep the computer awake and the Jenkins server running.',
  ],
  guide: ConnectionGuide.remoteAccess,
);

ConnectionDiagnosis _vpnOff(String host) => ConnectionDiagnosis(
  cause: ConnectionCause.vpnOff,
  title: 'The VPN may be off on this phone',
  explanation:
      '$host looks like a Tailscale address. It only routes to your computer '
      'while the VPN is on and both devices use the same account.',
  fixTips: [
    'Open Tailscale (or WireGuard) on the phone and switch it on.',
    'Check the phone and the computer are signed into the same account.',
    'Make sure the computer is awake and online.',
  ],
  guide: ConnectionGuide.remoteAccess,
);

ConnectionDiagnosis _certificate(String host) => ConnectionDiagnosis(
  cause: ConnectionCause.certificate,
  title: 'The certificate wasn’t trusted',
  explanation:
      '$host presented a security certificate the phone can’t verify. This '
      'is common with self-signed certificates and tunnel URLs.',
  fixTips: [
    'Check the address is spelled correctly and uses https://.',
    'Check the phone’s date and time are correct.',
    'Install a trusted certificate, or use a private VPN instead of a public tunnel.',
  ],
  guide: ConnectionGuide.remoteAccess,
);

ConnectionDiagnosis _network(String host) => ConnectionDiagnosis(
  cause: ConnectionCause.network,
  title: 'The server didn’t answer',
  explanation:
      'A request to $host timed out or was refused. The app can’t tell from '
      'the phone whether the network, the server, or something between them '
      'is at fault.',
  fixTips: [
    'Check the phone has internet access in Safari.',
    'Check the server is awake and its service is running.',
    'Try again in a moment.',
  ],
);

ConnectionDiagnosis _other() => const ConnectionDiagnosis(
  cause: ConnectionCause.other,
  title: 'Something else went wrong',
  explanation:
      'The server answered, but the request didn’t complete. The message on '
      'the previous screen has the detail.',
  fixTips: ['Check the message, then try again.'],
);

/// The IPv4 octets of a host, or null for a name or malformed address.
List<int>? _ipv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return null;
  final bytes = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value < 0 || value > 255) return null;
    bytes.add(value);
  }
  return bytes;
}

bool _isPrivate(List<int>? ipv4) {
  if (ipv4 == null) return false;
  if (ipv4[0] == 10 || ipv4[0] == 127) return true;
  if (ipv4[0] == 192 && ipv4[1] == 168) return true;
  if (ipv4[0] == 172 && ipv4[1] >= 16 && ipv4[1] <= 31) return true;
  return false;
}
