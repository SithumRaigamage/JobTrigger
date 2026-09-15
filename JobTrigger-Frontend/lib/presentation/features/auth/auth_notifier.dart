import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/session_signal.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/auth/user_dto.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/auth/user.dart';

part 'auth_notifier.g.dart';

const _cachedUserKey = 'cached_user';

/// Holds the app-wide session — `go_router`'s redirect
/// (`presentation/navigation/app_router.dart`) watches this.
///
/// P2-04: rehydration on app start deliberately does *not* make a network
/// call to validate the token. This matches the old app's
/// `AuthenticationManager.init()`, which just checked Keychain for a token
/// and treated its presence as "logged in" — if the token has actually
/// expired, the first authenticated request naturally 401s and
/// `buildBackendDio`'s interceptor (Phase 1) clears the session, which this
/// notifier picks up on its next rebuild.
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    // P6-10: without this, nothing ever notices a 401 cleared the session
    // out from under an already-`Authenticated` state — the UI would stay
    // stuck showing the authenticated screen until a full app restart.
    // `previous == null` on the first call is the listener's own
    // registration, not a real signal — skip it.
    ref.listen(sessionSignalProvider, (previous, next) {
      if (previous != null && next != previous) logout();
    });

    final secureStorage = ref.watch(secureStorageProvider);
    final token = await secureStorage.readToken();
    if (token == null) return const Unauthenticated();

    final cachedUser = await _readCachedUser();
    if (cachedUser == null) {
      // A token with no cached user is an inconsistent local state (e.g.
      // app storage partially cleared) — treat as logged out rather than
      // showing an authenticated screen with no user to display.
      await secureStorage.clear();
      return const Unauthenticated();
    }
    return Authenticated(cachedUser);
  }

  /// Called by `LoginNotifier`/`SignupNotifier` on a successful auth call —
  /// see `docs/state-management.md`'s "Feature: auth" section.
  Future<void> setSession(User user, String token) async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.saveToken(token);
    await _writeCachedUser(user);
    state = AsyncData(Authenticated(user));
  }

  Future<void> logout() async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.clear();
    await _clearCachedUser();
    state = const AsyncData(Unauthenticated());
  }

  Future<User?> _readCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedUserKey);
    if (raw == null) return null;
    return UserDto.fromJson(jsonDecode(raw) as Map<String, dynamic>).toDomain();
  }

  Future<void> _writeCachedUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedUserKey,
      jsonEncode(UserDto(id: user.id, email: user.email).toJson()),
    );
  }

  Future<void> _clearCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserKey);
  }
}
