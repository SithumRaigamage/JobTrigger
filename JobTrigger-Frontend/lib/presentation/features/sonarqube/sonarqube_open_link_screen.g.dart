// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_open_link_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The project a `jobtrigger://app/sonarqube/project?key=` link names
/// (`US-SQ-LINK-02`), looked up on the active credential.

@ProviderFor(sonarQubeLinkedProject)
final sonarQubeLinkedProjectProvider = SonarQubeLinkedProjectFamily._();

/// The project a `jobtrigger://app/sonarqube/project?key=` link names
/// (`US-SQ-LINK-02`), looked up on the active credential.

final class SonarQubeLinkedProjectProvider
    extends
        $FunctionalProvider<
          AsyncValue<SonarQubeProject>,
          SonarQubeProject,
          FutureOr<SonarQubeProject>
        >
    with $FutureModifier<SonarQubeProject>, $FutureProvider<SonarQubeProject> {
  /// The project a `jobtrigger://app/sonarqube/project?key=` link names
  /// (`US-SQ-LINK-02`), looked up on the active credential.
  SonarQubeLinkedProjectProvider._({
    required SonarQubeLinkedProjectFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeLinkedProjectProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeLinkedProjectHash();

  @override
  String toString() {
    return r'sonarQubeLinkedProjectProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SonarQubeProject> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SonarQubeProject> create(Ref ref) {
    final argument = this.argument as String;
    return sonarQubeLinkedProject(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeLinkedProjectProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeLinkedProjectHash() =>
    r'b62f233c8596c9e5ee4cc1b771278aae2bfb4cdb';

/// The project a `jobtrigger://app/sonarqube/project?key=` link names
/// (`US-SQ-LINK-02`), looked up on the active credential.

final class SonarQubeLinkedProjectFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SonarQubeProject>, String> {
  SonarQubeLinkedProjectFamily._()
    : super(
        retry: null,
        name: r'sonarQubeLinkedProjectProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The project a `jobtrigger://app/sonarqube/project?key=` link names
  /// (`US-SQ-LINK-02`), looked up on the active credential.

  SonarQubeLinkedProjectProvider call(String key) =>
      SonarQubeLinkedProjectProvider._(argument: key, from: this);

  @override
  String toString() => r'sonarQubeLinkedProjectProvider';
}
