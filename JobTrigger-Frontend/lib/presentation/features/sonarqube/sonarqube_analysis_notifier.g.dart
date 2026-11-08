// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_analysis_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A project's analysis history (`US-SQ-QUALITY-04`), keyed by project key.

@ProviderFor(SonarQubeAnalysisNotifier)
final sonarQubeAnalysisNotifierProvider = SonarQubeAnalysisNotifierFamily._();

/// A project's analysis history (`US-SQ-QUALITY-04`), keyed by project key.
final class SonarQubeAnalysisNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeAnalysisNotifier,
          List<SonarQubeAnalysis>
        > {
  /// A project's analysis history (`US-SQ-QUALITY-04`), keyed by project key.
  SonarQubeAnalysisNotifierProvider._({
    required SonarQubeAnalysisNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeAnalysisNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeAnalysisNotifierHash();

  @override
  String toString() {
    return r'sonarQubeAnalysisNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeAnalysisNotifier create() => SonarQubeAnalysisNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeAnalysisNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeAnalysisNotifierHash() =>
    r'a4d62cf2df6428f823e5be21bd663be101e9f390';

/// A project's analysis history (`US-SQ-QUALITY-04`), keyed by project key.

final class SonarQubeAnalysisNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeAnalysisNotifier,
          AsyncValue<List<SonarQubeAnalysis>>,
          List<SonarQubeAnalysis>,
          FutureOr<List<SonarQubeAnalysis>>,
          String
        > {
  SonarQubeAnalysisNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeAnalysisNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's analysis history (`US-SQ-QUALITY-04`), keyed by project key.

  SonarQubeAnalysisNotifierProvider call(String projectKey) =>
      SonarQubeAnalysisNotifierProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeAnalysisNotifierProvider';
}

/// A project's analysis history (`US-SQ-QUALITY-04`), keyed by project key.

abstract class _$SonarQubeAnalysisNotifier
    extends $AsyncNotifier<List<SonarQubeAnalysis>> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<List<SonarQubeAnalysis>> build(String projectKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<SonarQubeAnalysis>>,
              List<SonarQubeAnalysis>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<SonarQubeAnalysis>>,
                List<SonarQubeAnalysis>
              >,
              AsyncValue<List<SonarQubeAnalysis>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
