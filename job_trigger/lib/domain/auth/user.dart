/// Ported from `User.swift`. The JWT is deliberately not a field here — it
/// only ever lives in secure storage, attached to requests by
/// `dioBackend`'s interceptor (see `docs/data-models.md`).
class User {
  const User({required this.id, required this.email});

  final String id;
  final String email;
}
