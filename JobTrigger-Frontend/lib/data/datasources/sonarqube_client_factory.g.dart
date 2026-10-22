// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_client_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rebuilt whenever the active SonarQube credential changes — mirrors
/// `gitHubClientProvider` exactly. Throws if there's no active credential
/// yet; screens that depend on this are expected to already gate on a
/// credential being configured before reaching that point.

@ProviderFor(sonarQubeClient)
final sonarQubeClientProvider = SonarQubeClientProvider._();

/// Rebuilt whenever the active SonarQube credential changes — mirrors
/// `gitHubClientProvider` exactly. Throws if there's no active credential
/// yet; screens that depend on this are expected to already gate on a
/// credential being configured before reaching that point.

final class SonarQubeClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Rebuilt whenever the active SonarQube credential changes — mirrors
  /// `gitHubClientProvider` exactly. Throws if there's no active credential
  /// yet; screens that depend on this are expected to already gate on a
  /// credential being configured before reaching that point.
  SonarQubeClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return sonarQubeClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$sonarQubeClientHash() => r'e8ffc50b852dbf98bafd96c4349d0927a43e356d';
