// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_worst_files_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A project's worst files for one measure (`US-SQ-QUALITY-12`).

@ProviderFor(sonarQubeWorstFiles)
final sonarQubeWorstFilesProvider = SonarQubeWorstFilesFamily._();

/// A project's worst files for one measure (`US-SQ-QUALITY-12`).

final class SonarQubeWorstFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SonarQubeWorstFiles>,
          SonarQubeWorstFiles,
          FutureOr<SonarQubeWorstFiles>
        >
    with
        $FutureModifier<SonarQubeWorstFiles>,
        $FutureProvider<SonarQubeWorstFiles> {
  /// A project's worst files for one measure (`US-SQ-QUALITY-12`).
  SonarQubeWorstFilesProvider._({
    required SonarQubeWorstFilesFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeWorstFilesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeWorstFilesHash();

  @override
  String toString() {
    return r'sonarQubeWorstFilesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SonarQubeWorstFiles> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SonarQubeWorstFiles> create(Ref ref) {
    final argument = this.argument as (String, String);
    return sonarQubeWorstFiles(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeWorstFilesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeWorstFilesHash() =>
    r'c3c4392294219f5b6cb10995acca58da8d404914';

/// A project's worst files for one measure (`US-SQ-QUALITY-12`).

final class SonarQubeWorstFilesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SonarQubeWorstFiles>,
          (String, String)
        > {
  SonarQubeWorstFilesFamily._()
    : super(
        retry: null,
        name: r'sonarQubeWorstFilesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's worst files for one measure (`US-SQ-QUALITY-12`).

  SonarQubeWorstFilesProvider call(String projectKey, String metric) =>
      SonarQubeWorstFilesProvider._(argument: (projectKey, metric), from: this);

  @override
  String toString() => r'sonarQubeWorstFilesProvider';
}
