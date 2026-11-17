// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_issue_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The server's own view of one issue (`US-SQ-WRITE-01..03`): current status
/// and assignee, the transitions it offers, the comments. It is the only
/// source for what the page shows about those, so a change appears once the
/// server has accepted it and this has been read again.

@ProviderFor(sonarQubeIssueDetail)
final sonarQubeIssueDetailProvider = SonarQubeIssueDetailFamily._();

/// The server's own view of one issue (`US-SQ-WRITE-01..03`): current status
/// and assignee, the transitions it offers, the comments. It is the only
/// source for what the page shows about those, so a change appears once the
/// server has accepted it and this has been read again.

final class SonarQubeIssueDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SonarQubeIssueDetail>,
          SonarQubeIssueDetail,
          FutureOr<SonarQubeIssueDetail>
        >
    with
        $FutureModifier<SonarQubeIssueDetail>,
        $FutureProvider<SonarQubeIssueDetail> {
  /// The server's own view of one issue (`US-SQ-WRITE-01..03`): current status
  /// and assignee, the transitions it offers, the comments. It is the only
  /// source for what the page shows about those, so a change appears once the
  /// server has accepted it and this has been read again.
  SonarQubeIssueDetailProvider._({
    required SonarQubeIssueDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeIssueDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeIssueDetailHash();

  @override
  String toString() {
    return r'sonarQubeIssueDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SonarQubeIssueDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SonarQubeIssueDetail> create(Ref ref) {
    final argument = this.argument as String;
    return sonarQubeIssueDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeIssueDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeIssueDetailHash() =>
    r'fa034c03aa2bb73ba23109afd389575652816fd0';

/// The server's own view of one issue (`US-SQ-WRITE-01..03`): current status
/// and assignee, the transitions it offers, the comments. It is the only
/// source for what the page shows about those, so a change appears once the
/// server has accepted it and this has been read again.

final class SonarQubeIssueDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SonarQubeIssueDetail>, String> {
  SonarQubeIssueDetailFamily._()
    : super(
        retry: null,
        name: r'sonarQubeIssueDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The server's own view of one issue (`US-SQ-WRITE-01..03`): current status
  /// and assignee, the transitions it offers, the comments. It is the only
  /// source for what the page shows about those, so a change appears once the
  /// server has accepted it and this has been read again.

  SonarQubeIssueDetailProvider call(String issueKey) =>
      SonarQubeIssueDetailProvider._(argument: issueKey, from: this);

  @override
  String toString() => r'sonarQubeIssueDetailProvider';
}
