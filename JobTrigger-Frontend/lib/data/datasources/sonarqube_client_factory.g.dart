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

String _$sonarQubeClientHash() => r'ba0f8d3dd6bd8f5e152bcfe56b89a32e6fa6867e';

/// The branch or pull request each project's views read (`US-SQ-QUALITY-10`),
/// per project: switching one project's ref leaves the others on main. The
/// SonarQube client watches this map, so a change rebuilds it and every
/// notifier on that project reloads through its own provider.

@ProviderFor(SonarQubeBranchSelectionsNotifier)
final sonarQubeBranchSelectionsNotifierProvider =
    SonarQubeBranchSelectionsNotifierProvider._();

/// The branch or pull request each project's views read (`US-SQ-QUALITY-10`),
/// per project: switching one project's ref leaves the others on main. The
/// SonarQube client watches this map, so a change rebuilds it and every
/// notifier on that project reloads through its own provider.
final class SonarQubeBranchSelectionsNotifierProvider
    extends
        $NotifierProvider<
          SonarQubeBranchSelectionsNotifier,
          Map<String, SonarQubeBranchRef>
        > {
  /// The branch or pull request each project's views read (`US-SQ-QUALITY-10`),
  /// per project: switching one project's ref leaves the others on main. The
  /// SonarQube client watches this map, so a change rebuilds it and every
  /// notifier on that project reloads through its own provider.
  SonarQubeBranchSelectionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeBranchSelectionsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$sonarQubeBranchSelectionsNotifierHash();

  @$internal
  @override
  SonarQubeBranchSelectionsNotifier create() =>
      SonarQubeBranchSelectionsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, SonarQubeBranchRef> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, SonarQubeBranchRef>>(
        value,
      ),
    );
  }
}

String _$sonarQubeBranchSelectionsNotifierHash() =>
    r'5c9f9099e12cce10aece58c21977d60be75d781b';

/// The branch or pull request each project's views read (`US-SQ-QUALITY-10`),
/// per project: switching one project's ref leaves the others on main. The
/// SonarQube client watches this map, so a change rebuilds it and every
/// notifier on that project reloads through its own provider.

abstract class _$SonarQubeBranchSelectionsNotifier
    extends $Notifier<Map<String, SonarQubeBranchRef>> {
  Map<String, SonarQubeBranchRef> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, SonarQubeBranchRef>,
              Map<String, SonarQubeBranchRef>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, SonarQubeBranchRef>,
                Map<String, SonarQubeBranchRef>
              >,
              Map<String, SonarQubeBranchRef>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
