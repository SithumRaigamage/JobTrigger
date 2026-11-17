// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_pins_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pins for the active SonarQube credential, in the order pinned. Pins
/// belong to a credential — a different server has different projects — so
/// the list is rebuilt and reloaded whenever the credential changes. Local
/// only: SonarQube's own server-side favourites (`api/favorites`) would be a
/// write and are `US-SQ-WRITE-*` territory.

@ProviderFor(SonarQubePinsNotifier)
final sonarQubePinsNotifierProvider = SonarQubePinsNotifierProvider._();

/// Pins for the active SonarQube credential, in the order pinned. Pins
/// belong to a credential — a different server has different projects — so
/// the list is rebuilt and reloaded whenever the credential changes. Local
/// only: SonarQube's own server-side favourites (`api/favorites`) would be a
/// write and are `US-SQ-WRITE-*` territory.
final class SonarQubePinsNotifierProvider
    extends
        $NotifierProvider<SonarQubePinsNotifier, List<PinnedSonarQubeProject>> {
  /// Pins for the active SonarQube credential, in the order pinned. Pins
  /// belong to a credential — a different server has different projects — so
  /// the list is rebuilt and reloaded whenever the credential changes. Local
  /// only: SonarQube's own server-side favourites (`api/favorites`) would be a
  /// write and are `US-SQ-WRITE-*` territory.
  SonarQubePinsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubePinsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubePinsNotifierHash();

  @$internal
  @override
  SonarQubePinsNotifier create() => SonarQubePinsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PinnedSonarQubeProject> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PinnedSonarQubeProject>>(value),
    );
  }
}

String _$sonarQubePinsNotifierHash() =>
    r'c185c3d553f0874afbfed40e8ad0b1c51f853738';

/// Pins for the active SonarQube credential, in the order pinned. Pins
/// belong to a credential — a different server has different projects — so
/// the list is rebuilt and reloaded whenever the credential changes. Local
/// only: SonarQube's own server-side favourites (`api/favorites`) would be a
/// write and are `US-SQ-WRITE-*` territory.

abstract class _$SonarQubePinsNotifier
    extends $Notifier<List<PinnedSonarQubeProject>> {
  List<PinnedSonarQubeProject> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<List<PinnedSonarQubeProject>, List<PinnedSonarQubeProject>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<PinnedSonarQubeProject>,
                List<PinnedSonarQubeProject>
              >,
              List<PinnedSonarQubeProject>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The pinned keys alone, for sorting and for the pin buttons.

@ProviderFor(sonarQubePinnedKeys)
final sonarQubePinnedKeysProvider = SonarQubePinnedKeysProvider._();

/// The pinned keys alone, for sorting and for the pin buttons.

final class SonarQubePinnedKeysProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// The pinned keys alone, for sorting and for the pin buttons.
  SonarQubePinnedKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubePinnedKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubePinnedKeysHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return sonarQubePinnedKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$sonarQubePinnedKeysHash() =>
    r'62da97a03688a28dce7af1c8df0df8fadde158f5';
