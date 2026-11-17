// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_issue_context.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The rule's name and the code around one issue (`US-SQ-QUALITY-06`).
/// Keyed by the issue, which is equal to another with the same key.

@ProviderFor(sonarQubeIssueContext)
final sonarQubeIssueContextProvider = SonarQubeIssueContextFamily._();

/// The rule's name and the code around one issue (`US-SQ-QUALITY-06`).
/// Keyed by the issue, which is equal to another with the same key.

final class SonarQubeIssueContextProvider
    extends
        $FunctionalProvider<
          AsyncValue<SonarQubeIssueContext>,
          SonarQubeIssueContext,
          FutureOr<SonarQubeIssueContext>
        >
    with
        $FutureModifier<SonarQubeIssueContext>,
        $FutureProvider<SonarQubeIssueContext> {
  /// The rule's name and the code around one issue (`US-SQ-QUALITY-06`).
  /// Keyed by the issue, which is equal to another with the same key.
  SonarQubeIssueContextProvider._({
    required SonarQubeIssueContextFamily super.from,
    required SonarQubeIssue super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeIssueContextProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeIssueContextHash();

  @override
  String toString() {
    return r'sonarQubeIssueContextProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SonarQubeIssueContext> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SonarQubeIssueContext> create(Ref ref) {
    final argument = this.argument as SonarQubeIssue;
    return sonarQubeIssueContext(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeIssueContextProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeIssueContextHash() =>
    r'8dee17e3da4457079a78c41c6c3ae26a04ea8b4f';

/// The rule's name and the code around one issue (`US-SQ-QUALITY-06`).
/// Keyed by the issue, which is equal to another with the same key.

final class SonarQubeIssueContextFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SonarQubeIssueContext>,
          SonarQubeIssue
        > {
  SonarQubeIssueContextFamily._()
    : super(
        retry: null,
        name: r'sonarQubeIssueContextProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The rule's name and the code around one issue (`US-SQ-QUALITY-06`).
  /// Keyed by the issue, which is equal to another with the same key.

  SonarQubeIssueContextProvider call(SonarQubeIssue issue) =>
      SonarQubeIssueContextProvider._(argument: issue, from: this);

  @override
  String toString() => r'sonarQubeIssueContextProvider';
}
