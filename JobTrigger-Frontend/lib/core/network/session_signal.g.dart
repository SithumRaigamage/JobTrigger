// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_signal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fired by `buildBackendDio`'s `onUnauthorized` callback when a 401 clears
/// the stored session — see `backend_api_client.dart`. `core/network`
/// mustn't import `presentation/features/auth/auth_notifier.dart` directly
/// (would break the layering in `docs/architecture.md`), so this is a
/// dependency-free bridge: `AuthNotifier` listens to it instead (P6-10 —
/// found while testing the 401-mid-session flow that nothing previously
/// caused `AuthNotifier` to ever notice a session had been cleared out from
/// under it, leaving the UI stuck showing "authenticated" until a full
/// app restart).

@ProviderFor(SessionSignal)
final sessionSignalProvider = SessionSignalProvider._();

/// Fired by `buildBackendDio`'s `onUnauthorized` callback when a 401 clears
/// the stored session — see `backend_api_client.dart`. `core/network`
/// mustn't import `presentation/features/auth/auth_notifier.dart` directly
/// (would break the layering in `docs/architecture.md`), so this is a
/// dependency-free bridge: `AuthNotifier` listens to it instead (P6-10 —
/// found while testing the 401-mid-session flow that nothing previously
/// caused `AuthNotifier` to ever notice a session had been cleared out from
/// under it, leaving the UI stuck showing "authenticated" until a full
/// app restart).
final class SessionSignalProvider
    extends $NotifierProvider<SessionSignal, int> {
  /// Fired by `buildBackendDio`'s `onUnauthorized` callback when a 401 clears
  /// the stored session — see `backend_api_client.dart`. `core/network`
  /// mustn't import `presentation/features/auth/auth_notifier.dart` directly
  /// (would break the layering in `docs/architecture.md`), so this is a
  /// dependency-free bridge: `AuthNotifier` listens to it instead (P6-10 —
  /// found while testing the 401-mid-session flow that nothing previously
  /// caused `AuthNotifier` to ever notice a session had been cleared out from
  /// under it, leaving the UI stuck showing "authenticated" until a full
  /// app restart).
  SessionSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionSignalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionSignalHash();

  @$internal
  @override
  SessionSignal create() => SessionSignal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$sessionSignalHash() => r'053bffa9bc24b0a4e758f9d757267418e44e55fb';

/// Fired by `buildBackendDio`'s `onUnauthorized` callback when a 401 clears
/// the stored session — see `backend_api_client.dart`. `core/network`
/// mustn't import `presentation/features/auth/auth_notifier.dart` directly
/// (would break the layering in `docs/architecture.md`), so this is a
/// dependency-free bridge: `AuthNotifier` listens to it instead (P6-10 —
/// found while testing the 401-mid-session flow that nothing previously
/// caused `AuthNotifier` to ever notice a session had been cleared out from
/// under it, leaving the UI stuck showing "authenticated" until a full
/// app restart).

abstract class _$SessionSignal extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
