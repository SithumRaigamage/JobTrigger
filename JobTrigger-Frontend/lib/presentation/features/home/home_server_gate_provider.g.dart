// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_server_gate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeServerGate)
final homeServerGateProvider = HomeServerGateProvider._();

final class HomeServerGateProvider
    extends $FunctionalProvider<HomeServerGate, HomeServerGate, HomeServerGate>
    with $Provider<HomeServerGate> {
  HomeServerGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeServerGateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeServerGateHash();

  @$internal
  @override
  $ProviderElement<HomeServerGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeServerGate create(Ref ref) {
    return homeServerGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeServerGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeServerGate>(value),
    );
  }
}

String _$homeServerGateHash() => r'731cbd87f65f71a531c88e8d84a6487d5f4033e5';
