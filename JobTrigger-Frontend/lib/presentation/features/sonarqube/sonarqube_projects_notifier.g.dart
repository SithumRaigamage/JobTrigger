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
    r'1fd55ba1533823feeb93b3f79438c9d556d78df9';

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

@ProviderFor(SonarQubeProjectSortNotifier)
final sonarQubeProjectSortNotifierProvider =
    SonarQubeProjectSortNotifierProvider._();

final class SonarQubeProjectSortNotifierProvider
    extends
        $NotifierProvider<SonarQubeProjectSortNotifier, SonarQubeProjectSort> {
  SonarQubeProjectSortNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeProjectSortNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeProjectSortNotifierHash();

  @$internal
  @override
  SonarQubeProjectSortNotifier create() => SonarQubeProjectSortNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeProjectSort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeProjectSort>(value),
    );
  }
}

String _$sonarQubeProjectSortNotifierHash() =>
    r'2cdf3d30904bccf9a4d8fe66e7251cdcaf59e3e3';

abstract class _$SonarQubeProjectSortNotifier
    extends $Notifier<SonarQubeProjectSort> {
  SonarQubeProjectSort build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SonarQubeProjectSort, SonarQubeProjectSort>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SonarQubeProjectSort, SonarQubeProjectSort>,
              SonarQubeProjectSort,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// "Failing only": narrow the list to projects whose gate failed or warns.

@ProviderFor(SonarQubeFailingOnly)
final sonarQubeFailingOnlyProvider = SonarQubeFailingOnlyProvider._();

/// "Failing only": narrow the list to projects whose gate failed or warns.
final class SonarQubeFailingOnlyProvider
    extends $NotifierProvider<SonarQubeFailingOnly, bool> {
  /// "Failing only": narrow the list to projects whose gate failed or warns.
  SonarQubeFailingOnlyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeFailingOnlyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeFailingOnlyHash();

  @$internal
  @override
  SonarQubeFailingOnly create() => SonarQubeFailingOnly();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sonarQubeFailingOnlyHash() =>
    r'8fd45cb414bcdaa07a248b09c6378665f7231c6d';

/// "Failing only": narrow the list to projects whose gate failed or warns.

abstract class _$SonarQubeFailingOnly extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
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

/// Loaded projects matching the search, narrowed by "failing only" and
/// ordered by the chosen sort.

@ProviderFor(filteredSonarQubeProjects)
final filteredSonarQubeProjectsProvider = FilteredSonarQubeProjectsProvider._();

/// Loaded projects matching the search, narrowed by "failing only" and
/// ordered by the chosen sort.

final class FilteredSonarQubeProjectsProvider
    extends
        $FunctionalProvider<
          List<SonarQubeProject>,
          List<SonarQubeProject>,
          List<SonarQubeProject>
        >
    with $Provider<List<SonarQubeProject>> {
  /// Loaded projects matching the search, narrowed by "failing only" and
  /// ordered by the chosen sort.
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
    r'805bc2ab53fec46c8fdbb6b8c3a7826b7fd0ed49';
