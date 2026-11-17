import 'package:sentry_flutter/sentry_flutter.dart';

import 'credential_shapes.dart';

/// E3 / PE-24: every crash report passes through here before it is sent or
/// cached on the phone. Mirrors the backend and website scrubbers; the rules
/// are in `docs/error-reporting.md`:
///
/// - no request or response bodies, no cookies
/// - sensitive headers removed (`Authorization`, `x-auth-token`, `Cookie`,
///   `Set-Cookie`, `PRIVATE-TOKEN`, anything with token/secret/key in the name)
/// - query strings and `user:pass@` removed from every URL
/// - credential shapes redacted from every string
/// - no breadcrumbs; the user is an opaque id at most, never an email
///
/// [scrubEvent] returns a scrubbed copy, or null (drop the event) when it
/// can't be sure the copy is clean. It never returns the original.
const redacted = '[redacted]';

const _sensitiveHeaders = {
  'authorization',
  'x-auth-token',
  'cookie',
  'set-cookie',
  'private-token',
  'proxy-authorization',
};

final _sensitiveFragment = RegExp(
  'token|secret|key|password|passwd|credential',
);

/// True for a header or field name that must never leave the phone.
bool isSensitiveName(String name) {
  final lower = name.toLowerCase();
  if (_sensitiveHeaders.contains(lower)) return true;
  if (_sensitiveFragment.hasMatch(lower)) return true;
  return credentialKeys.contains(normaliseKey(lower));
}

final _urlInText = RegExp(
  r'''\b([a-z][a-z0-9+.-]*://)([^\s/?#@"'<>]*@)?([^\s?#"'<>]*)(\?[^\s#"'<>]*)?(#[^\s"'<>]*)?''',
  caseSensitive: false,
);
final _namedValue = RegExp(
  r'''(["']?)([A-Za-z_][\w.-]*)\1(\s*[:=]\s*)(["']?)([^"'\s,&;}]+)\4''',
);
final _authScheme = RegExp(
  r'\b(Basic|Bearer)\s+[A-Za-z0-9+/._~=-]{8,}',
  caseSensitive: false,
);

/// [text] with every credential shape and URL secret removed.
String scrubString(String text) {
  return text
      .replaceAllMapped(_urlInText, (m) => '${m.group(1)}${m.group(3)}')
      .replaceAllMapped(_authScheme, (m) => '${m.group(1)} $redacted')
      .replaceAllMapped(_namedValue, (m) {
        final name = m.group(2)!;
        if (isSensitiveName(name) && m.group(5) != redacted) {
          final quote = m.group(1)!;
          return '$quote$name$quote${m.group(3)}${m.group(4)}$redacted${m.group(4)}';
        }
        return m.group(0)!;
      })
      .replaceAll(tokenShape, redacted);
}

/// A URL without credentials, query or fragment.
String scrubUrl(String url) =>
    scrubString(url.replaceFirst(RegExp(r'[?#].*$', dotAll: true), ''));

Map<String, dynamic> scrubHeaders(Map<String, dynamic>? headers) {
  final kept = <String, dynamic>{};
  (headers ?? const {}).forEach((name, value) {
    if (isSensitiveName(name)) return;
    kept[name] = value is String ? scrubString(value) : value;
  });
  return kept;
}

dynamic _scrubValue(dynamic value, [int depth = 0]) {
  if (value is String) return scrubString(value);
  if (value is List) {
    return [for (final item in value) _scrubValue(item, depth + 1)];
  }
  if (value is Map) {
    if (depth > 12) return redacted;
    return {
      for (final entry in value.entries)
        '${entry.key}': isSensitiveName('${entry.key}')
            ? redacted
            : _scrubValue(entry.value, depth + 1),
    };
  }
  return value;
}

/// True when [text] still holds something the repository guard would flag.
bool hasResidue(String text) {
  if (tokenShape.hasMatch(text)) return true;
  for (final match in basicHeader.allMatches(text)) {
    final captured = match.group(1)!;
    if (captured != redacted && tokenValue.hasMatch(captured)) return true;
  }
  for (final match in bearerHeader.allMatches(text)) {
    final captured = match.group(1)!;
    if (captured != redacted && tokenValue.hasMatch(captured)) return true;
  }
  for (final match in mongodbUri.allMatches(text)) {
    final captured = match.group(1)!;
    if (captured != redacted && !placeholderPassword.hasMatch(captured)) {
      return true;
    }
  }
  return false;
}

/// Sentry's own identifiers (`event_id`, the trace and span ids) are random
/// 16/32-character hex strings, the same shape as a Jenkins API token, so the
/// token rule redacted them and the host rejected the event ("event_id: Input
/// should be a valid UUID", found live on the lab's GlitchTip, P6-08). They
/// carry nothing about the user, so the originals are put back, and only when
/// they really are plain hex.
void _restoreIdentifiers(
  Map<String, dynamic> original,
  Map<String, dynamic> clean,
) {
  final hex = RegExp(r'^[0-9a-fA-F-]{16,36}$');
  final id = original['event_id'];
  if (id is String && hex.hasMatch(id)) clean['event_id'] = id;
  final trace = (original['contexts'] is Map)
      ? (original['contexts'] as Map)['trace']
      : null;
  final cleanContexts = clean['contexts'];
  if (trace is Map && cleanContexts is Map && cleanContexts['trace'] is Map) {
    for (final key in ['trace_id', 'span_id', 'parent_span_id']) {
      final value = trace[key];
      if (value is String && hex.hasMatch(value)) {
        (cleanContexts['trace'] as Map)[key] = value;
      }
    }
  }
}

/// The scrubbed copy of a Sentry event as JSON, or null to drop it.
Map<String, dynamic>? scrubEventJson(Map<String, dynamic> event) {
  try {
    final clean = Map<String, dynamic>.from(_scrubValue(event) as Map);
    clean
      ..remove('server_name')
      ..remove('breadcrumbs');
    final request = event['request'];
    if (request is Map) {
      final method = request['method'];
      final url = request['url'];
      clean['request'] = {
        if (method is String) 'method': method,
        if (url is String) 'url': scrubUrl(url),
        'headers': scrubHeaders(
          request['headers'] is Map
              ? Map<String, dynamic>.from(request['headers'] as Map)
              : null,
        ),
      };
    }
    final user = event['user'];
    if (user is Map && user['id'] != null) {
      clean['user'] = {'id': '${user['id']}'};
    } else {
      clean.remove('user');
    }
    // The residue check runs first: the identifiers below are hex, the shape
    // it looks for, and are only put back once everything else is verified.
    if (hasResidue(clean.toString())) return null;
    _restoreIdentifiers(event, clean);
    return clean;
  } on Object {
    return null;
  }
}

/// [scrubEventJson] for a [SentryEvent].
SentryEvent? scrubEvent(SentryEvent event) {
  final json = scrubEventJson(event.toJson());
  return json == null ? null : SentryEvent.fromJson(json);
}
