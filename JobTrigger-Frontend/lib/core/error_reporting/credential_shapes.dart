/// The shapes of credential material (E3). Mirrors
/// `JobTrigger-Backend/security/credentialShapes.js` and
/// `JobTrigger-Web/src/error-reporting/credential-shapes.ts`; the list is in
/// `docs/error-reporting.md`. Keep the three in step.
library;

/// A Jenkins token: 32 hex characters, or the modern `11`-prefixed form. Not
/// part of a longer hex string, so a 40-character git SHA never matches.
final tokenShape = RegExp(r'(?<![0-9a-f])((?:11)?[0-9a-f]{32})(?![0-9a-f])');
final tokenValue = RegExp(r'^(11)?[0-9a-f]{32}$');

/// Keys whose value is a credential, after [normaliseKey].
const credentialKeys = <String>{
  'password',
  'passwd',
  'pass',
  'token',
  'apitoken',
  'accesstoken',
  'authtoken',
  'bearertoken',
  'jenkinstoken',
  'personalaccesstoken',
  'pat',
  'secret',
  'paramtoken',
  'credential',
  'credentials',
  'auth',
  'authorization',
  'apikey',
  'apisecret',
  'privatekey',
};

final basicHeader = RegExp(r'Basic\s+([A-Za-z0-9+/]{12,}={0,2})');
final bearerHeader = RegExp(r'Bearer\s+([A-Za-z0-9._-]{16,})');
final mongodbUri = RegExp(
  r'''mongodb(?:\+srv)?://[^:@/\s'"`]+:([^@/\s'"`]+)@''',
);
final placeholderPassword = RegExp(r'^(<[^<>]*>|\$\{[^{}]*\}|\*+)$');

/// Lower-cased, with everything but letters removed.
String normaliseKey(String key) =>
    key.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
