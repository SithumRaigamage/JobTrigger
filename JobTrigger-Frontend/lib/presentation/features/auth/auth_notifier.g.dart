// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AuthNotifier)
final authNotifierProvider = AuthNotifierProvider._();

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
final class AuthNotifierProvider
    extends $AsyncNotifierProvider<AuthNotifier, AuthState> {
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
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();
}

String _$authNotifierHash() => r'53ce1600bb1e7cb4f3779ba916975ae442ea8b6e';

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

abstract class _$AuthNotifier extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
