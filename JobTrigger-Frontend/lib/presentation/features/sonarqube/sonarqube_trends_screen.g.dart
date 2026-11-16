// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_trends_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One measure's history for a project (`US-SQ-QUALITY-11`).

@ProviderFor(sonarQubeMeasureHistory)
final sonarQubeMeasureHistoryProvider = SonarQubeMeasureHistoryFamily._();

/// One measure's history for a project (`US-SQ-QUALITY-11`).

final class SonarQubeMeasureHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<SonarQubeMeasureHistory>,
          SonarQubeMeasureHistory,
          FutureOr<SonarQubeMeasureHistory>
        >
    with
        $FutureModifier<SonarQubeMeasureHistory>,
        $FutureProvider<SonarQubeMeasureHistory> {
  /// One measure's history for a project (`US-SQ-QUALITY-11`).
  SonarQubeMeasureHistoryProvider._({
    required SonarQubeMeasureHistoryFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeMeasureHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeMeasureHistoryHash();

  @override
  String toString() {
    return r'sonarQubeMeasureHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SonarQubeMeasureHistory> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SonarQubeMeasureHistory> create(Ref ref) {
    final argument = this.argument as (String, String);
    return sonarQubeMeasureHistory(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeMeasureHistoryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeMeasureHistoryHash() =>
    r'fe56a1eb0ddece60631b0802a1efe953d752757d';

/// One measure's history for a project (`US-SQ-QUALITY-11`).

final class SonarQubeMeasureHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SonarQubeMeasureHistory>,
          (String, String)
        > {
  SonarQubeMeasureHistoryFamily._()
    : super(
        retry: null,
        name: r'sonarQubeMeasureHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One measure's history for a project (`US-SQ-QUALITY-11`).

  SonarQubeMeasureHistoryProvider call(String projectKey, String metric) =>
      SonarQubeMeasureHistoryProvider._(
        argument: (projectKey, metric),
        from: this,
      );

  @override
  String toString() => r'sonarQubeMeasureHistoryProvider';
}
