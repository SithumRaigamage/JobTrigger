// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_projects_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active credential's projects (`US-SQ-PROJ-01`).
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.

@ProviderFor(SonarQubeProjectsNotifier)
final sonarQubeProjectsNotifierProvider = SonarQubeProjectsNotifierProvider._();

/// The active credential's projects (`US-SQ-PROJ-01`).
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.
final class SonarQubeProjectsNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeProjectsNotifier,
          List<SonarQubeProject>
        > {
  /// The active credential's projects (`US-SQ-PROJ-01`).
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
    r'f646e60f0bbda80655f954b8acb9113aa6787a81';

/// The active credential's projects (`US-SQ-PROJ-01`).
/// `sonarQubeRepositoryProvider` rebuilds when the active credential
/// changes, so switching credentials refetches on its own.

abstract class _$SonarQubeProjectsNotifier
    extends $AsyncNotifier<List<SonarQubeProject>> {
  FutureOr<List<SonarQubeProject>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<SonarQubeProject>>, List<SonarQubeProject>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SonarQubeProject>>,
                List<SonarQubeProject>
              >,
              AsyncValue<List<SonarQubeProject>>,
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

/// Projects matching the search, by name or key, case-insensitively.

@ProviderFor(filteredSonarQubeProjects)
final filteredSonarQubeProjectsProvider = FilteredSonarQubeProjectsProvider._();

/// Projects matching the search, by name or key, case-insensitively.

final class FilteredSonarQubeProjectsProvider
    extends
        $FunctionalProvider<
          List<SonarQubeProject>,
          List<SonarQubeProject>,
          List<SonarQubeProject>
        >
    with $Provider<List<SonarQubeProject>> {
  /// Projects matching the search, by name or key, case-insensitively.
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
    r'da02834b9813bd92c628c4953f1e69ee0030641a';
