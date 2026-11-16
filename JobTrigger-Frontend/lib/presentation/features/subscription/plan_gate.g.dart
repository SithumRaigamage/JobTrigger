// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planGate)
final planGateProvider = PlanGateProvider._();

final class PlanGateProvider
    extends $FunctionalProvider<PlanGate, PlanGate, PlanGate>
    with $Provider<PlanGate> {
  PlanGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planGateHash();

  @$internal
  @override
  $ProviderElement<PlanGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanGate create(Ref ref) {
    return planGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanGate>(value),
    );
  }
}

String _$planGateHash() => r'9f4bbf9bbdd94c8d2757bf2e2595661d96864fb0';

/// P20-25: the saved-credential counts for the add-server pre-check. A list
/// that can't be loaded counts as empty: the backend enforces the real
/// limit either way, and this pre-check only saves a round trip.

@ProviderFor(credentialCounts)
final credentialCountsProvider = CredentialCountsProvider._();

/// P20-25: the saved-credential counts for the add-server pre-check. A list
/// that can't be loaded counts as empty: the backend enforces the real
/// limit either way, and this pre-check only saves a round trip.

final class CredentialCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CredentialCounts>,
          CredentialCounts,
          FutureOr<CredentialCounts>
        >
    with $FutureModifier<CredentialCounts>, $FutureProvider<CredentialCounts> {
  /// P20-25: the saved-credential counts for the add-server pre-check. A list
  /// that can't be loaded counts as empty: the backend enforces the real
  /// limit either way, and this pre-check only saves a round trip.
  CredentialCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialCountsHash();

  @$internal
  @override
  $FutureProviderElement<CredentialCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CredentialCounts> create(Ref ref) {
    return credentialCounts(ref);
  }
}

String _$credentialCountsHash() => r'da43280c91c7f350401be2b2b14abb1bafd8bfd6';

/// P20-25: the tools a Free user can't switch to. On a plan without
/// `multiTool`, the user keeps the tool(s) they already saved servers for;
/// every other tool needs Pro. Empty with billing off, or before any
/// server is saved (the first tool is free to choose).

@ProviderFor(proLockedTools)
final proLockedToolsProvider = ProLockedToolsProvider._();

/// P20-25: the tools a Free user can't switch to. On a plan without
/// `multiTool`, the user keeps the tool(s) they already saved servers for;
/// every other tool needs Pro. Empty with billing off, or before any
/// server is saved (the first tool is free to choose).

final class ProLockedToolsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<CiTool>>,
          Set<CiTool>,
          FutureOr<Set<CiTool>>
        >
    with $FutureModifier<Set<CiTool>>, $FutureProvider<Set<CiTool>> {
  /// P20-25: the tools a Free user can't switch to. On a plan without
  /// `multiTool`, the user keeps the tool(s) they already saved servers for;
  /// every other tool needs Pro. Empty with billing off, or before any
  /// server is saved (the first tool is free to choose).
  ProLockedToolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proLockedToolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proLockedToolsHash();

  @$internal
  @override
  $FutureProviderElement<Set<CiTool>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<CiTool>> create(Ref ref) {
    return proLockedTools(ref);
  }
}

String _$proLockedToolsHash() => r'c63e24d32204bde6d44e793e863420bbbc0a5d8b';
