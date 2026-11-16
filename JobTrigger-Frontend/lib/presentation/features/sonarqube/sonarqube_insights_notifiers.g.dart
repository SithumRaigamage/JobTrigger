// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_insights_notifiers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A project's analysis status (`US-SQ-CE-01`), read when the page opens and
/// on pull-to-refresh — never polled, like the rest of the epic.

@ProviderFor(SonarQubeAnalysisStatusNotifier)
final sonarQubeAnalysisStatusNotifierProvider =
    SonarQubeAnalysisStatusNotifierFamily._();

/// A project's analysis status (`US-SQ-CE-01`), read when the page opens and
/// on pull-to-refresh — never polled, like the rest of the epic.
final class SonarQubeAnalysisStatusNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeAnalysisStatusNotifier,
          SonarQubeAnalysisStatus
        > {
  /// A project's analysis status (`US-SQ-CE-01`), read when the page opens and
  /// on pull-to-refresh — never polled, like the rest of the epic.
  SonarQubeAnalysisStatusNotifierProvider._({
    required SonarQubeAnalysisStatusNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeAnalysisStatusNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeAnalysisStatusNotifierHash();

  @override
  String toString() {
    return r'sonarQubeAnalysisStatusNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeAnalysisStatusNotifier create() => SonarQubeAnalysisStatusNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeAnalysisStatusNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeAnalysisStatusNotifierHash() =>
    r'e3245fdb811d0141007f5226a246f8f6d0181e24';

/// A project's analysis status (`US-SQ-CE-01`), read when the page opens and
/// on pull-to-refresh — never polled, like the rest of the epic.

final class SonarQubeAnalysisStatusNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeAnalysisStatusNotifier,
          AsyncValue<SonarQubeAnalysisStatus>,
          SonarQubeAnalysisStatus,
          FutureOr<SonarQubeAnalysisStatus>,
          String
        > {
  SonarQubeAnalysisStatusNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeAnalysisStatusNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's analysis status (`US-SQ-CE-01`), read when the page opens and
  /// on pull-to-refresh — never polled, like the rest of the epic.

  SonarQubeAnalysisStatusNotifierProvider call(String projectKey) =>
      SonarQubeAnalysisStatusNotifierProvider._(
        argument: projectKey,
        from: this,
      );

  @override
  String toString() => r'sonarQubeAnalysisStatusNotifierProvider';
}

/// A project's analysis status (`US-SQ-CE-01`), read when the page opens and
/// on pull-to-refresh — never polled, like the rest of the epic.

abstract class _$SonarQubeAnalysisStatusNotifier
    extends $AsyncNotifier<SonarQubeAnalysisStatus> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<SonarQubeAnalysisStatus> build(String projectKey);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<SonarQubeAnalysisStatus>,
              SonarQubeAnalysisStatus
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SonarQubeAnalysisStatus>,
                SonarQubeAnalysisStatus
              >,
              AsyncValue<SonarQubeAnalysisStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(SonarQubeMeasureScopeNotifier)
final sonarQubeMeasureScopeNotifierProvider =
    SonarQubeMeasureScopeNotifierProvider._();

final class SonarQubeMeasureScopeNotifierProvider
    extends
        $NotifierProvider<
          SonarQubeMeasureScopeNotifier,
          SonarQubeMeasureScope
        > {
  SonarQubeMeasureScopeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeMeasureScopeNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeMeasureScopeNotifierHash();

  @$internal
  @override
  SonarQubeMeasureScopeNotifier create() => SonarQubeMeasureScopeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeMeasureScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeMeasureScope>(value),
    );
  }
}

String _$sonarQubeMeasureScopeNotifierHash() =>
    r'a6591ad483e89eb0cffaff1e409bb44ceee2e9d5';

abstract class _$SonarQubeMeasureScopeNotifier
    extends $Notifier<SonarQubeMeasureScope> {
  SonarQubeMeasureScope build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SonarQubeMeasureScope, SonarQubeMeasureScope>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SonarQubeMeasureScope, SonarQubeMeasureScope>,
              SonarQubeMeasureScope,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// A project's new-code measures (`US-SQ-QUALITY-08`). Empty when the server
/// computes none — the switch is then hidden rather than showing zeros.

@ProviderFor(SonarQubeNewCodeMeasuresNotifier)
final sonarQubeNewCodeMeasuresNotifierProvider =
    SonarQubeNewCodeMeasuresNotifierFamily._();

/// A project's new-code measures (`US-SQ-QUALITY-08`). Empty when the server
/// computes none — the switch is then hidden rather than showing zeros.
final class SonarQubeNewCodeMeasuresNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeNewCodeMeasuresNotifier,
          Map<String, String>
        > {
  /// A project's new-code measures (`US-SQ-QUALITY-08`). Empty when the server
  /// computes none — the switch is then hidden rather than showing zeros.
  SonarQubeNewCodeMeasuresNotifierProvider._({
    required SonarQubeNewCodeMeasuresNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeNewCodeMeasuresNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeNewCodeMeasuresNotifierHash();

  @override
  String toString() {
    return r'sonarQubeNewCodeMeasuresNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeNewCodeMeasuresNotifier create() =>
      SonarQubeNewCodeMeasuresNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeNewCodeMeasuresNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeNewCodeMeasuresNotifierHash() =>
    r'86dab7e2313aae0df1ee983f65729bee8a81bbc2';

/// A project's new-code measures (`US-SQ-QUALITY-08`). Empty when the server
/// computes none — the switch is then hidden rather than showing zeros.

final class SonarQubeNewCodeMeasuresNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeNewCodeMeasuresNotifier,
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>,
          String
        > {
  SonarQubeNewCodeMeasuresNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeNewCodeMeasuresNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's new-code measures (`US-SQ-QUALITY-08`). Empty when the server
  /// computes none — the switch is then hidden rather than showing zeros.

  SonarQubeNewCodeMeasuresNotifierProvider call(String projectKey) =>
      SonarQubeNewCodeMeasuresNotifierProvider._(
        argument: projectKey,
        from: this,
      );

  @override
  String toString() => r'sonarQubeNewCodeMeasuresNotifierProvider';
}

/// A project's new-code measures (`US-SQ-QUALITY-08`). Empty when the server
/// computes none — the switch is then hidden rather than showing zeros.

abstract class _$SonarQubeNewCodeMeasuresNotifier
    extends $AsyncNotifier<Map<String, String>> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<Map<String, String>> build(String projectKey);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, String>>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, String>>, Map<String, String>>,
              AsyncValue<Map<String, String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Each measure's change since the previous analysis (`US-SQ-QUALITY-09`),
/// keyed by metric; a metric with one data point is absent.

@ProviderFor(SonarQubeMeasureDeltasNotifier)
final sonarQubeMeasureDeltasNotifierProvider =
    SonarQubeMeasureDeltasNotifierFamily._();

/// Each measure's change since the previous analysis (`US-SQ-QUALITY-09`),
/// keyed by metric; a metric with one data point is absent.
final class SonarQubeMeasureDeltasNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeMeasureDeltasNotifier,
          Map<String, SonarQubeMeasureDelta>
        > {
  /// Each measure's change since the previous analysis (`US-SQ-QUALITY-09`),
  /// keyed by metric; a metric with one data point is absent.
  SonarQubeMeasureDeltasNotifierProvider._({
    required SonarQubeMeasureDeltasNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeMeasureDeltasNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeMeasureDeltasNotifierHash();

  @override
  String toString() {
    return r'sonarQubeMeasureDeltasNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeMeasureDeltasNotifier create() => SonarQubeMeasureDeltasNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeMeasureDeltasNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeMeasureDeltasNotifierHash() =>
    r'6e97a9eb42cfaf0776e72048a4840eaafc2040f8';

/// Each measure's change since the previous analysis (`US-SQ-QUALITY-09`),
/// keyed by metric; a metric with one data point is absent.

final class SonarQubeMeasureDeltasNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeMeasureDeltasNotifier,
          AsyncValue<Map<String, SonarQubeMeasureDelta>>,
          Map<String, SonarQubeMeasureDelta>,
          FutureOr<Map<String, SonarQubeMeasureDelta>>,
          String
        > {
  SonarQubeMeasureDeltasNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeMeasureDeltasNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Each measure's change since the previous analysis (`US-SQ-QUALITY-09`),
  /// keyed by metric; a metric with one data point is absent.

  SonarQubeMeasureDeltasNotifierProvider call(String projectKey) =>
      SonarQubeMeasureDeltasNotifierProvider._(
        argument: projectKey,
        from: this,
      );

  @override
  String toString() => r'sonarQubeMeasureDeltasNotifierProvider';
}

/// Each measure's change since the previous analysis (`US-SQ-QUALITY-09`),
/// keyed by metric; a metric with one data point is absent.

abstract class _$SonarQubeMeasureDeltasNotifier
    extends $AsyncNotifier<Map<String, SonarQubeMeasureDelta>> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<Map<String, SonarQubeMeasureDelta>> build(String projectKey);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, SonarQubeMeasureDelta>>,
              Map<String, SonarQubeMeasureDelta>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, SonarQubeMeasureDelta>>,
                Map<String, SonarQubeMeasureDelta>
              >,
              AsyncValue<Map<String, SonarQubeMeasureDelta>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The unresolved issues assigned to the token's user, across every project
/// (`US-SQ-ISSUES-01`). Filtering re-queries the server; "Load more" pages it.

@ProviderFor(SonarQubeMyIssuesNotifier)
final sonarQubeMyIssuesNotifierProvider = SonarQubeMyIssuesNotifierProvider._();

/// The unresolved issues assigned to the token's user, across every project
/// (`US-SQ-ISSUES-01`). Filtering re-queries the server; "Load more" pages it.
final class SonarQubeMyIssuesNotifierProvider
    extends
        $AsyncNotifierProvider<SonarQubeMyIssuesNotifier, SonarQubeMyIssues> {
  /// The unresolved issues assigned to the token's user, across every project
  /// (`US-SQ-ISSUES-01`). Filtering re-queries the server; "Load more" pages it.
  SonarQubeMyIssuesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeMyIssuesNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeMyIssuesNotifierHash();

  @$internal
  @override
  SonarQubeMyIssuesNotifier create() => SonarQubeMyIssuesNotifier();
}

String _$sonarQubeMyIssuesNotifierHash() =>
    r'4901533b240a5c3087fbd4691c39652699c0924f';

/// The unresolved issues assigned to the token's user, across every project
/// (`US-SQ-ISSUES-01`). Filtering re-queries the server; "Load more" pages it.

abstract class _$SonarQubeMyIssuesNotifier
    extends $AsyncNotifier<SonarQubeMyIssues> {
  FutureOr<SonarQubeMyIssues> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SonarQubeMyIssues>, SonarQubeMyIssues>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SonarQubeMyIssues>, SonarQubeMyIssues>,
              AsyncValue<SonarQubeMyIssues>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
