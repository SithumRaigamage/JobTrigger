// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeWidgetBridge)
final homeWidgetBridgeProvider = HomeWidgetBridgeProvider._();

final class HomeWidgetBridgeProvider
    extends
        $FunctionalProvider<
          HomeWidgetBridge,
          HomeWidgetBridge,
          HomeWidgetBridge
        >
    with $Provider<HomeWidgetBridge> {
  HomeWidgetBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetBridgeHash();

  @$internal
  @override
  $ProviderElement<HomeWidgetBridge> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeWidgetBridge create(Ref ref) {
    return homeWidgetBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeWidgetBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeWidgetBridge>(value),
    );
  }
}

String _$homeWidgetBridgeHash() => r'814ae41cb26ab81ed0351ef48464ae0c184e1b37';
