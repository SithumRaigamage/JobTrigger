// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
/// version/build/legal-link info from `GET /api/appinfo`. Follows the
/// standard shape from `docs/architecture.md §4`.
///
/// US-PROF-03 "cached with a short TTL": kept for the session (the update
/// gate reads it too), and fetched again by [refreshIfStale] once it is
/// older than [ttl]. No timer: nothing is left running when nobody looks.

@ProviderFor(AppInfoNotifier)
final appInfoNotifierProvider = AppInfoNotifierProvider._();

/// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
/// version/build/legal-link info from `GET /api/appinfo`. Follows the
/// standard shape from `docs/architecture.md §4`.
///
/// US-PROF-03 "cached with a short TTL": kept for the session (the update
/// gate reads it too), and fetched again by [refreshIfStale] once it is
/// older than [ttl]. No timer: nothing is left running when nobody looks.
final class AppInfoNotifierProvider
    extends $AsyncNotifierProvider<AppInfoNotifier, AppInfo> {
  /// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
  /// version/build/legal-link info from `GET /api/appinfo`. Follows the
  /// standard shape from `docs/architecture.md §4`.
  ///
  /// US-PROF-03 "cached with a short TTL": kept for the session (the update
  /// gate reads it too), and fetched again by [refreshIfStale] once it is
  /// older than [ttl]. No timer: nothing is left running when nobody looks.
  AppInfoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInfoNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInfoNotifierHash();

  @$internal
  @override
  AppInfoNotifier create() => AppInfoNotifier();
}

String _$appInfoNotifierHash() => r'1f2832cce256814e1f774d9de6cd2ba24e10379e';

/// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
/// version/build/legal-link info from `GET /api/appinfo`. Follows the
/// standard shape from `docs/architecture.md §4`.
///
/// US-PROF-03 "cached with a short TTL": kept for the session (the update
/// gate reads it too), and fetched again by [refreshIfStale] once it is
/// older than [ttl]. No timer: nothing is left running when nobody looks.

abstract class _$AppInfoNotifier extends $AsyncNotifier<AppInfo> {
  FutureOr<AppInfo> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppInfo>, AppInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppInfo>, AppInfo>,
              AsyncValue<AppInfo>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
