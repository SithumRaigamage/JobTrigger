// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_issues_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The issue filter chips for one project (`US-SQ-QUALITY-03`).

@ProviderFor(SonarQubeIssueFilterNotifier)
final sonarQubeIssueFilterNotifierProvider =
    SonarQubeIssueFilterNotifierFamily._();

/// The issue filter chips for one project (`US-SQ-QUALITY-03`).
final class SonarQubeIssueFilterNotifierProvider
    extends
        $NotifierProvider<SonarQubeIssueFilterNotifier, SonarQubeIssueFilter> {
  /// The issue filter chips for one project (`US-SQ-QUALITY-03`).
  SonarQubeIssueFilterNotifierProvider._({
    required SonarQubeIssueFilterNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeIssueFilterNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeIssueFilterNotifierHash();

  @override
  String toString() {
    return r'sonarQubeIssueFilterNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeIssueFilterNotifier create() => SonarQubeIssueFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeIssueFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeIssueFilter>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeIssueFilterNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeIssueFilterNotifierHash() =>
    r'bae20ad03aaa2a1c5878aacb454b66b0ab5a268c';

/// The issue filter chips for one project (`US-SQ-QUALITY-03`).

final class SonarQubeIssueFilterNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeIssueFilterNotifier,
          SonarQubeIssueFilter,
          SonarQubeIssueFilter,
          SonarQubeIssueFilter,
          String
        > {
  SonarQubeIssueFilterNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeIssueFilterNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The issue filter chips for one project (`US-SQ-QUALITY-03`).

  SonarQubeIssueFilterNotifierProvider call(String projectKey) =>
      SonarQubeIssueFilterNotifierProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeIssueFilterNotifierProvider';
}

/// The issue filter chips for one project (`US-SQ-QUALITY-03`).

abstract class _$SonarQubeIssueFilterNotifier
    extends $Notifier<SonarQubeIssueFilter> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  SonarQubeIssueFilter build(String projectKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SonarQubeIssueFilter, SonarQubeIssueFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SonarQubeIssueFilter, SonarQubeIssueFilter>,
              SonarQubeIssueFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// A project's issues, server-filtered and paged (`US-SQ-QUALITY-03`).
/// Changing the filter rebuilds from page one.

@ProviderFor(SonarQubeIssuesNotifier)
final sonarQubeIssuesNotifierProvider = SonarQubeIssuesNotifierFamily._();

/// A project's issues, server-filtered and paged (`US-SQ-QUALITY-03`).
/// Changing the filter rebuilds from page one.
final class SonarQubeIssuesNotifierProvider
    extends $AsyncNotifierProvider<SonarQubeIssuesNotifier, SonarQubeIssues> {
  /// A project's issues, server-filtered and paged (`US-SQ-QUALITY-03`).
  /// Changing the filter rebuilds from page one.
  SonarQubeIssuesNotifierProvider._({
    required SonarQubeIssuesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeIssuesNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeIssuesNotifierHash();

  @override
  String toString() {
    return r'sonarQubeIssuesNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeIssuesNotifier create() => SonarQubeIssuesNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeIssuesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeIssuesNotifierHash() =>
    r'2362114e4bd9cd88eef363a7c9e2fe0f86f7e48f';

/// A project's issues, server-filtered and paged (`US-SQ-QUALITY-03`).
/// Changing the filter rebuilds from page one.

final class SonarQubeIssuesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeIssuesNotifier,
          AsyncValue<SonarQubeIssues>,
          SonarQubeIssues,
          FutureOr<SonarQubeIssues>,
          String
        > {
  SonarQubeIssuesNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeIssuesNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's issues, server-filtered and paged (`US-SQ-QUALITY-03`).
  /// Changing the filter rebuilds from page one.

  SonarQubeIssuesNotifierProvider call(String projectKey) =>
      SonarQubeIssuesNotifierProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeIssuesNotifierProvider';
}

/// A project's issues, server-filtered and paged (`US-SQ-QUALITY-03`).
/// Changing the filter rebuilds from page one.

abstract class _$SonarQubeIssuesNotifier
    extends $AsyncNotifier<SonarQubeIssues> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<SonarQubeIssues> build(String projectKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SonarQubeIssues>, SonarQubeIssues>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SonarQubeIssues>, SonarQubeIssues>,
              AsyncValue<SonarQubeIssues>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
