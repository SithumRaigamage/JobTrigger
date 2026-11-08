// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_last_analysis.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When a project was last analysed, from its analysis history: the newest
/// analysis, or null if it has never been analysed.
///
/// The project list normally carries this date, but a server may leave it
/// out; a project is only called "never analysed" when its history is
/// really empty, not when the list was silent.

@ProviderFor(sonarQubeLastAnalysis)
final sonarQubeLastAnalysisProvider = SonarQubeLastAnalysisFamily._();

/// When a project was last analysed, from its analysis history: the newest
/// analysis, or null if it has never been analysed.
///
/// The project list normally carries this date, but a server may leave it
/// out; a project is only called "never analysed" when its history is
/// really empty, not when the list was silent.

final class SonarQubeLastAnalysisProvider
    extends
        $FunctionalProvider<
          AsyncValue<DateTime?>,
          DateTime?,
          FutureOr<DateTime?>
        >
    with $FutureModifier<DateTime?>, $FutureProvider<DateTime?> {
  /// When a project was last analysed, from its analysis history: the newest
  /// analysis, or null if it has never been analysed.
  ///
  /// The project list normally carries this date, but a server may leave it
  /// out; a project is only called "never analysed" when its history is
  /// really empty, not when the list was silent.
  SonarQubeLastAnalysisProvider._({
    required SonarQubeLastAnalysisFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeLastAnalysisProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeLastAnalysisHash();

  @override
  String toString() {
    return r'sonarQubeLastAnalysisProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DateTime?> create(Ref ref) {
    final argument = this.argument as String;
    return sonarQubeLastAnalysis(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeLastAnalysisProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeLastAnalysisHash() =>
    r'8e61339ccc2d5d80220fc83d08811c4f59821c99';

/// When a project was last analysed, from its analysis history: the newest
/// analysis, or null if it has never been analysed.
///
/// The project list normally carries this date, but a server may leave it
/// out; a project is only called "never analysed" when its history is
/// really empty, not when the list was silent.

final class SonarQubeLastAnalysisFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DateTime?>, String> {
  SonarQubeLastAnalysisFamily._()
    : super(
        retry: null,
        name: r'sonarQubeLastAnalysisProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// When a project was last analysed, from its analysis history: the newest
  /// analysis, or null if it has never been analysed.
  ///
  /// The project list normally carries this date, but a server may leave it
  /// out; a project is only called "never analysed" when its history is
  /// really empty, not when the list was silent.

  SonarQubeLastAnalysisProvider call(String projectKey) =>
      SonarQubeLastAnalysisProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeLastAnalysisProvider';
}
