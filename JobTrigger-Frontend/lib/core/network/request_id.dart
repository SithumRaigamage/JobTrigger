import 'dart:math';

/// §19 (P13-26): the id the app sends as `x-request-id`
/// on every backend request, so a "Server error" the user reports can be
/// matched to the backend's log lines for that request.
///
/// 16 hex characters from a secure source: unguessable and well inside the
/// backend's accepted shape ([requestIdPattern]), which it otherwise
/// replaces with its own id.
String newRequestId([Random? random]) {
  final source = random ?? Random.secure();
  return List.generate(
    8,
    (_) => source.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Mirrors `JobTrigger-Backend/middleware/requestId.js`'s `INBOUND_ID`. An
/// id read back from a response is shown to the user only if it matches,
/// so a proxy or a foreign server can't put arbitrary text in the copy.
final requestIdPattern = RegExp(r'^[A-Za-z0-9._-]{1,64}$');
