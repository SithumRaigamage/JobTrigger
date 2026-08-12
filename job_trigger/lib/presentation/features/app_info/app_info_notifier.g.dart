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

@ProviderFor(AppInfoNotifier)
final appInfoNotifierProvider = AppInfoNotifierProvider._();

/// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
/// version/build/legal-link info from `GET /api/appinfo`. Follows the
/// standard shape from `docs/architecture.md §4`.
final class AppInfoNotifierProvider
    extends $AsyncNotifierProvider<AppInfoNotifier, AppInfo> {
  /// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
  /// version/build/legal-link info from `GET /api/appinfo`. Follows the
  /// standard shape from `docs/architecture.md §4`.
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

String _$appInfoNotifierHash() => r'4740535387d914b3538844359a19f3dd00a722e0';

/// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
/// version/build/legal-link info from `GET /api/appinfo`. Follows the
/// standard shape from `docs/architecture.md §4`.

abstract class _$AppInfoNotifier extends $AsyncNotifier<AppInfo> {
  FutureOr<AppInfo> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppInfo>, AppInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppInfo>, AppInfo>,
              AsyncValue<AppInfo>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
