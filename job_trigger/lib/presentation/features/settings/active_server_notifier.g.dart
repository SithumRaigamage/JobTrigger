// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_server_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently active Jenkins server. Ported from `ActiveServerManager.swift`,
/// but persists an id (not just a URL string) per `docs/state-management.md`.
///
/// A plain `Notifier`, not `AsyncNotifier` (state is `JenkinsServer?`,
/// available synchronously) — `build()` kicks off async rehydration and
/// updates `state` once it resolves, same pattern as `ThemeNotifier`
/// (Phase 1). Reuses `credentialsNotifierProvider`'s already-fetched list
/// rather than re-fetching — see `docs/state-management.md`'s "Rules of
/// thumb".

@ProviderFor(ActiveServerNotifier)
final activeServerNotifierProvider = ActiveServerNotifierProvider._();

/// Currently active Jenkins server. Ported from `ActiveServerManager.swift`,
/// but persists an id (not just a URL string) per `docs/state-management.md`.
///
/// A plain `Notifier`, not `AsyncNotifier` (state is `JenkinsServer?`,
/// available synchronously) — `build()` kicks off async rehydration and
/// updates `state` once it resolves, same pattern as `ThemeNotifier`
/// (Phase 1). Reuses `credentialsNotifierProvider`'s already-fetched list
/// rather than re-fetching — see `docs/state-management.md`'s "Rules of
/// thumb".
final class ActiveServerNotifierProvider
    extends $NotifierProvider<ActiveServerNotifier, JenkinsServer?> {
  /// Currently active Jenkins server. Ported from `ActiveServerManager.swift`,
  /// but persists an id (not just a URL string) per `docs/state-management.md`.
  ///
  /// A plain `Notifier`, not `AsyncNotifier` (state is `JenkinsServer?`,
  /// available synchronously) — `build()` kicks off async rehydration and
  /// updates `state` once it resolves, same pattern as `ThemeNotifier`
  /// (Phase 1). Reuses `credentialsNotifierProvider`'s already-fetched list
  /// rather than re-fetching — see `docs/state-management.md`'s "Rules of
  /// thumb".
  ActiveServerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeServerNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeServerNotifierHash();

  @$internal
  @override
  ActiveServerNotifier create() => ActiveServerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JenkinsServer? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JenkinsServer?>(value),
    );
  }
}

String _$activeServerNotifierHash() =>
    r'98ec198176feb6e4e8cf2e458d17dc6cd4e3c991';

/// Currently active Jenkins server. Ported from `ActiveServerManager.swift`,
/// but persists an id (not just a URL string) per `docs/state-management.md`.
///
/// A plain `Notifier`, not `AsyncNotifier` (state is `JenkinsServer?`,
/// available synchronously) — `build()` kicks off async rehydration and
/// updates `state` once it resolves, same pattern as `ThemeNotifier`
/// (Phase 1). Reuses `credentialsNotifierProvider`'s already-fetched list
/// rather than re-fetching — see `docs/state-management.md`'s "Rules of
/// thumb".

abstract class _$ActiveServerNotifier extends $Notifier<JenkinsServer?> {
  JenkinsServer? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<JenkinsServer?, JenkinsServer?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JenkinsServer?, JenkinsServer?>,
              JenkinsServer?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
