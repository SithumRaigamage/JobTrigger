// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_summaries_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the summaries loaded for every project in the list: watch it from a
/// screen that shows them. A side-effect-only provider, so the project list
/// and the overview share one rule instead of each wiring it up.

@ProviderFor(sonarQubeSummariesSync)
final sonarQubeSummariesSyncProvider = SonarQubeSummariesSyncProvider._();

/// Keeps the summaries loaded for every project in the list: watch it from a
/// screen that shows them. A side-effect-only provider, so the project list
/// and the overview share one rule instead of each wiring it up.

final class SonarQubeSummariesSyncProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Keeps the summaries loaded for every project in the list: watch it from a
  /// screen that shows them. A side-effect-only provider, so the project list
  /// and the overview share one rule instead of each wiring it up.
  SonarQubeSummariesSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeSummariesSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeSummariesSyncHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return sonarQubeSummariesSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sonarQubeSummariesSyncHash() =>
    r'955b3adf6ebbc2374c178d8b72cfc216f533b285';
