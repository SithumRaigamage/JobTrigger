/// AUD-52: what counts as a usable SonarQube URL — the same rules as a
/// Jenkins URL (`server_url.dart`), since the token goes to that server.
library;

import 'server_url.dart';

export 'server_url.dart' show isCleartextUrl, normalizeServerUrl;

/// Why [raw] can't be used, or null when it can.
String? sonarQubeUrlProblem(String raw) =>
    serverUrlProblem(raw, product: 'SonarQube');
