// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_quality_notifiers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A project's quality gate (`US-SQ-QUALITY-01`), keyed by project key.

@ProviderFor(SonarQubeQualityGateNotifier)
final sonarQubeQualityGateNotifierProvider =
    SonarQubeQualityGateNotifierFamily._();

/// A project's quality gate (`US-SQ-QUALITY-01`), keyed by project key.
final class SonarQubeQualityGateNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeQualityGateNotifier,
          SonarQubeQualityGate
        > {
  /// A project's quality gate (`US-SQ-QUALITY-01`), keyed by project key.
  SonarQubeQualityGateNotifierProvider._({
    required SonarQubeQualityGateNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeQualityGateNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeQualityGateNotifierHash();

  @override
  String toString() {
    return r'sonarQubeQualityGateNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeQualityGateNotifier create() => SonarQubeQualityGateNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeQualityGateNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeQualityGateNotifierHash() =>
    r'1113035363a80618e28e0a0689cb026b57226046';

/// A project's quality gate (`US-SQ-QUALITY-01`), keyed by project key.

final class SonarQubeQualityGateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeQualityGateNotifier,
          AsyncValue<SonarQubeQualityGate>,
          SonarQubeQualityGate,
          FutureOr<SonarQubeQualityGate>,
          String
        > {
  SonarQubeQualityGateNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeQualityGateNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's quality gate (`US-SQ-QUALITY-01`), keyed by project key.

  SonarQubeQualityGateNotifierProvider call(String projectKey) =>
      SonarQubeQualityGateNotifierProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeQualityGateNotifierProvider';
}

/// A project's quality gate (`US-SQ-QUALITY-01`), keyed by project key.

abstract class _$SonarQubeQualityGateNotifier
    extends $AsyncNotifier<SonarQubeQualityGate> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<SonarQubeQualityGate> build(String projectKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<SonarQubeQualityGate>, SonarQubeQualityGate>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SonarQubeQualityGate>,
                SonarQubeQualityGate
              >,
              AsyncValue<SonarQubeQualityGate>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// A project's key measures (`US-SQ-QUALITY-02`): metric → value, with
/// metrics the server didn't compute absent.

@ProviderFor(SonarQubeMeasuresNotifier)
final sonarQubeMeasuresNotifierProvider = SonarQubeMeasuresNotifierFamily._();

/// A project's key measures (`US-SQ-QUALITY-02`): metric → value, with
/// metrics the server didn't compute absent.
final class SonarQubeMeasuresNotifierProvider
    extends
        $AsyncNotifierProvider<SonarQubeMeasuresNotifier, Map<String, String>> {
  /// A project's key measures (`US-SQ-QUALITY-02`): metric → value, with
  /// metrics the server didn't compute absent.
  SonarQubeMeasuresNotifierProvider._({
    required SonarQubeMeasuresNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeMeasuresNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeMeasuresNotifierHash();

  @override
  String toString() {
    return r'sonarQubeMeasuresNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeMeasuresNotifier create() => SonarQubeMeasuresNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeMeasuresNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeMeasuresNotifierHash() =>
    r'3501788cddf92e64a8742221f7c8cf3f144e6333';

/// A project's key measures (`US-SQ-QUALITY-02`): metric → value, with
/// metrics the server didn't compute absent.

final class SonarQubeMeasuresNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeMeasuresNotifier,
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>,
          String
        > {
  SonarQubeMeasuresNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeMeasuresNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's key measures (`US-SQ-QUALITY-02`): metric → value, with
  /// metrics the server didn't compute absent.

  SonarQubeMeasuresNotifierProvider call(String projectKey) =>
      SonarQubeMeasuresNotifierProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeMeasuresNotifierProvider';
}

/// A project's key measures (`US-SQ-QUALITY-02`): metric → value, with
/// metrics the server didn't compute absent.

abstract class _$SonarQubeMeasuresNotifier
    extends $AsyncNotifier<Map<String, String>> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<Map<String, String>> build(String projectKey);
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, () => build(_$args));
  }
}
