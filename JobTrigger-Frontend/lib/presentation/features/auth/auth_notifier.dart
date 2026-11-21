import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/session_signal.dart';
import '../../../core/platform/home_widget_bridge.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/cache/job_tree_cache.dart';
import '../../../data/cache/sonarqube_cache.dart';
import '../../../data/cache/user_scoped_prefs.dart';
import '../../../data/demo/demo_data.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../data/models/auth/user_dto.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/auth/auth_validation.dart';
import '../../../domain/auth/user.dart';
import '../../common_widgets/toast_controller.dart';
import '../notifications/build_watch_notifier.dart';

part 'auth_notifier.g.dart';

const _cachedUserKey = 'cached_user';

/// P19-01: whether the session outlives an app restart — the "Remember me"
/// checkbox. A missing key means `true`, so sessions that predate the flag
/// aren't signed out by the update.
const _keepSignedInKey = 'keep_signed_in';

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
      if (previous != null && next != previous) {
        // US-AUTH-05: say why the user is back at the login screen.
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.warning,
              title: 'Session expired',
              message: 'Your session has expired. Please log in again.',
            );
        logout();
      }
    });

    // E2 (PE-14): demo mode is signed in without a session. Nothing is read
    // from secure storage, and there is nothing to refresh or wipe.
    if (ref.read(demoModeNotifierProvider)) {
      return const Authenticated(demoUser);
    }

    final secureStorage = ref.watch(secureStorageProvider);
    // US-AUTH-03: an unreadable keystore entry (a platform error) means "no
    // session", never a crash or a redirect loop; what's there is wiped.
    final String? token;
    try {
      token = await secureStorage.readToken();
    } on Object {
      try {
        await _wipeLocalSession();
      } on Object {
        // Best effort: the store itself is what failed.
      }
      return const Unauthenticated();
    }
    if (token == null) return const Unauthenticated();

    // P19-01: an unticked "Remember me" session ends with the app.
    if (!await _readKeepSignedIn()) {
      await _wipeLocalSession();
      return const Unauthenticated();
    }

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
  ///
  /// [keepSignedIn] (P19-01) is whether the session survives an app
  /// restart; null leaves the stored choice alone, as `changePassword` does.
  Future<void> setSession(
    User user,
    String token, {
    String? refreshToken,
    bool? keepSignedIn,
  }) async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.saveToken(token);
    if (refreshToken != null) {
      await secureStorage.saveRefreshToken(refreshToken);
    }
    await _writeCachedUser(user);
    if (keepSignedIn != null) await _writeKeepSignedIn(keepSignedIn);
    state = AsyncData(Authenticated(user));
  }

  /// AUD-26: revokes every session on every device, then signs out here.
  /// Returns the failure when the server couldn't be told (still signed
  /// in, so the user can retry), or null.
  Future<AppFailure?> logoutEverywhere() async {
    final result = await ref.read(authRepositoryProvider).logoutEverywhere();
    if (result case Err(:final error)) return error;
    await logout();
    return null;
  }

  /// AUD-48: changes the password. The backend revokes every session, this
  /// device's included, and returns a fresh one, which is stored here so
  /// the user stays signed in. Returns why it didn't happen (a
  /// [FormValidationError] or an [AppFailure]), or null.
  Future<Object?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      return const FormValidationError('Enter your current password.');
    }
    if (!AuthValidation.isValidPassword(newPassword)) {
      return const FormValidationError(
        'The new password needs at least '
        '${AuthValidation.minPasswordLength} characters.',
      );
    }
    if (newPassword != confirmPassword) {
      return const FormValidationError("The new passwords don't match.");
    }
    final result = await ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    switch (result) {
      case Ok(:final value):
        await setSession(
          value.user,
          value.token,
          refreshToken: value.refreshToken,
        );
        return null;
      case Err(:final error):
        return error;
    }
  }

  /// AUD-48: deletes the account and everything stored with it on the
  /// backend, then clears this device as [logout] does. Returns why it
  /// didn't happen, or null; nothing local changes on failure.
  Future<Object?> deleteAccount(String password) async {
    if (password.isEmpty) {
      return const FormValidationError('Enter your password to confirm.');
    }
    final result = await ref
        .read(authRepositoryProvider)
        .deleteAccount(password: password);
    if (result case Err(:final error)) return error;
    await logout();
    return null;
  }

  /// E2 (PE-12): "Try the demo" on the sign-in screen. Signs in as the
  /// sample user, with no backend call and no stored session.
  Future<void> enterDemo() async {
    // Let the startup session check finish first; it would otherwise
    // overwrite the state set below.
    await future;
    await ref.read(demoModeNotifierProvider.notifier).enter();
    state = const AsyncData(Authenticated(demoUser));
  }

  /// E2 (PE-12): "Exit demo". Clears everything demo mode set on this device
  /// (the active ids and pins it saved, its cached listings and the
  /// scripted run, which lives in the demo repository) and returns to
  /// sign-in.
  Future<void> exitDemo() async {
    await ref.read(demoModeNotifierProvider.notifier).exit();
    await clearUserScopedPrefs();
    try {
      await ref.read(jobTreeCacheProvider).clearServer(demoJenkinsServer.id);
    } on Object {
      // Best effort: the OS may already have purged the cache directory.
    }
    ref.invalidate(buildWatchNotifierProvider);
    state = const AsyncData(Unauthenticated());
  }

  Future<void> logout() async {
    if (ref.read(demoModeNotifierProvider)) return exitDemo();
    await _wipeLocalSession();
    state = const AsyncData(Unauthenticated());
  }

  /// Everything [logout] clears on this device, without touching [state] —
  /// [build] uses it too, where setting state isn't allowed.
  Future<void> _wipeLocalSession() async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.clear();
    await _clearCachedUser();
    await _clearKeepSignedIn();
    // US-JX-20: job names and URLs can be sensitive; don't leave them for
    // the next person to sign in on this device.
    try {
      await ref.read(jobTreeCacheProvider).clearAll();
    } on Object {
      // Best effort: the OS may already have purged the cache directory.
    }
    // US-SQ-OFFLINE-01: nor SonarQube's saved project list.
    try {
      await ref.read(sonarQubeCacheProvider).clearAll();
    } on Object {
      // Best effort, as above.
    }
    // US-JX-23: nor on the home screen.
    await ref.read(homeWidgetBridgeProvider).clear();
    // AUD-28: nor the active credentials, pins, views, or build watches.
    await clearUserScopedPrefs();
    // Reloads the (now empty) watches, which also cancels the background
    // check.
    ref.invalidate(buildWatchNotifierProvider);
  }

  Future<bool> _readKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepSignedInKey) ?? true;
  }

  Future<void> _writeKeepSignedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepSignedInKey, value);
  }

  Future<void> _clearKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keepSignedInKey);
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
