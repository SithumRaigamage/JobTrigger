// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_issue_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Searches issues across every project (`US-SQ-ISSUES-03`) by rule, tag,
/// file path or issue key. Nothing is requested until a term is submitted;
/// the type and severity chips narrow the same server query.

@ProviderFor(SonarQubeIssueSearchNotifier)
final sonarQubeIssueSearchNotifierProvider =
    SonarQubeIssueSearchNotifierProvider._();

/// Searches issues across every project (`US-SQ-ISSUES-03`) by rule, tag,
/// file path or issue key. Nothing is requested until a term is submitted;
/// the type and severity chips narrow the same server query.
final class SonarQubeIssueSearchNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeIssueSearchNotifier,
          SonarQubeIssueSearch
        > {
  /// Searches issues across every project (`US-SQ-ISSUES-03`) by rule, tag,
  /// file path or issue key. Nothing is requested until a term is submitted;
  /// the type and severity chips narrow the same server query.
  SonarQubeIssueSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeIssueSearchNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeIssueSearchNotifierHash();

  @$internal
  @override
  SonarQubeIssueSearchNotifier create() => SonarQubeIssueSearchNotifier();
}

String _$sonarQubeIssueSearchNotifierHash() =>
    r'd00f1ff0eafa04c0e7ccf789f878d23b8d7f7570';

/// Searches issues across every project (`US-SQ-ISSUES-03`) by rule, tag,
/// file path or issue key. Nothing is requested until a term is submitted;
/// the type and severity chips narrow the same server query.

abstract class _$SonarQubeIssueSearchNotifier
    extends $AsyncNotifier<SonarQubeIssueSearch> {
  FutureOr<SonarQubeIssueSearch> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<SonarQubeIssueSearch>, SonarQubeIssueSearch>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SonarQubeIssueSearch>,
                SonarQubeIssueSearch
              >,
              AsyncValue<SonarQubeIssueSearch>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
