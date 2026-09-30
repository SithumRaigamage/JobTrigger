// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-23: keeps the home-screen widget's snapshot in step with the
/// pinned jobs. Watching each pin's status keeps it fetched while the app
/// runs, and every refresh rewrites the snapshot. Watched from `main.dart`.

@ProviderFor(homeWidgetSync)
final homeWidgetSyncProvider = HomeWidgetSyncProvider._();

/// US-JX-23: keeps the home-screen widget's snapshot in step with the
/// pinned jobs. Watching each pin's status keeps it fetched while the app
/// runs, and every refresh rewrites the snapshot. Watched from `main.dart`.

final class HomeWidgetSyncProvider extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// US-JX-23: keeps the home-screen widget's snapshot in step with the
  /// pinned jobs. Watching each pin's status keeps it fetched while the app
  /// runs, and every refresh rewrites the snapshot. Watched from `main.dart`.
  HomeWidgetSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetSyncHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return homeWidgetSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$homeWidgetSyncHash() => r'94218c3356be4f5bbc9535136f255b58ea4ead2a';
