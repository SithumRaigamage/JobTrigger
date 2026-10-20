/// AUD-14: what counts as a usable Jenkins URL. The rules are shared with
/// every server credential; see `server_url.dart`.
library;

import 'server_url.dart';

export 'server_url.dart' show isCleartextUrl;

/// The URL trimmed and without trailing slashes, which the repository adds
/// back where a path needs one.
String normalizeJenkinsUrl(String raw) => normalizeServerUrl(raw);

/// Why [raw] can't be used, or null when it can.
String? jenkinsUrlProblem(String raw) =>
    serverUrlProblem(raw, product: 'Jenkins');
