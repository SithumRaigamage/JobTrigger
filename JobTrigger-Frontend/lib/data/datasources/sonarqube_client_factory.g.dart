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

String _$sonarQubeClientHash() => r'224474d1b69f159bb8457d044537b9a729ddd4d6';

/// The branch or pull request every project view reads (`US-SQ-QUALITY-10`).
/// The SonarQube client watches it, so choosing another ref rebuilds the
/// repositories and every screen reloads through its own notifier.

@ProviderFor(SonarQubeBranchRefNotifier)
final sonarQubeBranchRefNotifierProvider =
    SonarQubeBranchRefNotifierProvider._();

/// The branch or pull request every project view reads (`US-SQ-QUALITY-10`).
/// The SonarQube client watches it, so choosing another ref rebuilds the
/// repositories and every screen reloads through its own notifier.
final class SonarQubeBranchRefNotifierProvider
    extends $NotifierProvider<SonarQubeBranchRefNotifier, SonarQubeBranchRef> {
  /// The branch or pull request every project view reads (`US-SQ-QUALITY-10`).
  /// The SonarQube client watches it, so choosing another ref rebuilds the
  /// repositories and every screen reloads through its own notifier.
  SonarQubeBranchRefNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeBranchRefNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeBranchRefNotifierHash();

  @$internal
  @override
  SonarQubeBranchRefNotifier create() => SonarQubeBranchRefNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeBranchRef value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeBranchRef>(value),
    );
  }
}

String _$sonarQubeBranchRefNotifierHash() =>
    r'ce0a4fcc163602db0baf9c8e49a0935bae9e9815';

/// The branch or pull request every project view reads (`US-SQ-QUALITY-10`).
/// The SonarQube client watches it, so choosing another ref rebuilds the
/// repositories and every screen reloads through its own notifier.

abstract class _$SonarQubeBranchRefNotifier
    extends $Notifier<SonarQubeBranchRef> {
  SonarQubeBranchRef build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SonarQubeBranchRef, SonarQubeBranchRef>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SonarQubeBranchRef, SonarQubeBranchRef>,
              SonarQubeBranchRef,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
