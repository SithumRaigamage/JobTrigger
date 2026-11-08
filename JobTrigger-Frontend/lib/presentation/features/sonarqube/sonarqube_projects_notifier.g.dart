// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_projects_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active credential's projects, a page at a time.
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.

@ProviderFor(SonarQubeProjectsNotifier)
final sonarQubeProjectsNotifierProvider = SonarQubeProjectsNotifierProvider._();

/// The active credential's projects, a page at a time.
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.
final class SonarQubeProjectsNotifierProvider
    extends
        $AsyncNotifierProvider<SonarQubeProjectsNotifier, SonarQubeProjects> {
  /// The active credential's projects, a page at a time.
  /// `sonarQubeRepositoryProvider` rebuilds when the active credential
  /// changes, so switching credentials refetches on its own.
  SonarQubeProjectsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeProjectsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeProjectsNotifierHash();

  @$internal
  @override
  SonarQubeProjectsNotifier create() => SonarQubeProjectsNotifier();
}

String _$sonarQubeProjectsNotifierHash() =>
    r'2e25cb8fb5eef6a30cae55b221fa3277e313d161';

/// The active credential's projects, a page at a time.
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.

abstract class _$SonarQubeProjectsNotifier
    extends $AsyncNotifier<SonarQubeProjects> {
  FutureOr<SonarQubeProjects> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SonarQubeProjects>, SonarQubeProjects>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SonarQubeProjects>, SonarQubeProjects>,
              AsyncValue<SonarQubeProjects>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The search box's text (`US-SQ-PROJ-02`).

@ProviderFor(SonarQubeProjectSearch)
final sonarQubeProjectSearchProvider = SonarQubeProjectSearchProvider._();

/// The search box's text (`US-SQ-PROJ-02`).
final class SonarQubeProjectSearchProvider
    extends $NotifierProvider<SonarQubeProjectSearch, String> {
  /// The search box's text (`US-SQ-PROJ-02`).
  SonarQubeProjectSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeProjectSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeProjectSearchHash();

  @$internal
  @override
  SonarQubeProjectSearch create() => SonarQubeProjectSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$sonarQubeProjectSearchHash() =>
    r'14b7f821a21ac380057eb97510b7080a2bb67a9c';

/// The search box's text (`US-SQ-PROJ-02`).

abstract class _$SonarQubeProjectSearch extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Loaded projects matching the search, by name or key, case-insensitively.

@ProviderFor(filteredSonarQubeProjects)
final filteredSonarQubeProjectsProvider = FilteredSonarQubeProjectsProvider._();

/// Loaded projects matching the search, by name or key, case-insensitively.

final class FilteredSonarQubeProjectsProvider
    extends
        $FunctionalProvider<
          List<SonarQubeProject>,
          List<SonarQubeProject>,
          List<SonarQubeProject>
        >
    with $Provider<List<SonarQubeProject>> {
  /// Loaded projects matching the search, by name or key, case-insensitively.
  FilteredSonarQubeProjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredSonarQubeProjectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredSonarQubeProjectsHash();

  @$internal
  @override
  $ProviderElement<List<SonarQubeProject>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SonarQubeProject> create(Ref ref) {
    return filteredSonarQubeProjects(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SonarQubeProject> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SonarQubeProject>>(value),
    );
  }
}

String _$filteredSonarQubeProjectsHash() =>
    r'c68a598bada5de3486b91186122c7cb5b6b884d3';
