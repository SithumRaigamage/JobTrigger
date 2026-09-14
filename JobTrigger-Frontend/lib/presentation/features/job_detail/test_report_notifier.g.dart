// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_report_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PIPE-06. Family-keyed by build URL — a separate fetch from
/// `JobDetailNotifier` (testReport is its own Jenkins REST resource, not
/// embeddable in the job-detail `tree=` query). `null` data means no
/// published test report exists for this build, a normal state, not an
/// error.

@ProviderFor(TestReportNotifier)
final testReportNotifierProvider = TestReportNotifierFamily._();

/// US-PIPE-06. Family-keyed by build URL — a separate fetch from
/// `JobDetailNotifier` (testReport is its own Jenkins REST resource, not
/// embeddable in the job-detail `tree=` query). `null` data means no
/// published test report exists for this build, a normal state, not an
/// error.
final class TestReportNotifierProvider
    extends $AsyncNotifierProvider<TestReportNotifier, TestReport?> {
  /// US-PIPE-06. Family-keyed by build URL — a separate fetch from
  /// `JobDetailNotifier` (testReport is its own Jenkins REST resource, not
  /// embeddable in the job-detail `tree=` query). `null` data means no
  /// published test report exists for this build, a normal state, not an
  /// error.
  TestReportNotifierProvider._({
    required TestReportNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'testReportNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$testReportNotifierHash();

  @override
  String toString() {
    return r'testReportNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TestReportNotifier create() => TestReportNotifier();

  @override
  bool operator ==(Object other) {
    return other is TestReportNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$testReportNotifierHash() =>
    r'061425e5f25208c4bb4aab2f2934ecb9e37c7326';

/// US-PIPE-06. Family-keyed by build URL — a separate fetch from
/// `JobDetailNotifier` (testReport is its own Jenkins REST resource, not
/// embeddable in the job-detail `tree=` query). `null` data means no
/// published test report exists for this build, a normal state, not an
/// error.

final class TestReportNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TestReportNotifier,
          AsyncValue<TestReport?>,
          TestReport?,
          FutureOr<TestReport?>,
          String
        > {
  TestReportNotifierFamily._()
    : super(
        retry: null,
        name: r'testReportNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-PIPE-06. Family-keyed by build URL — a separate fetch from
  /// `JobDetailNotifier` (testReport is its own Jenkins REST resource, not
  /// embeddable in the job-detail `tree=` query). `null` data means no
  /// published test report exists for this build, a normal state, not an
  /// error.

  TestReportNotifierProvider call(String buildUrl) =>
      TestReportNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'testReportNotifierProvider';
}

/// US-PIPE-06. Family-keyed by build URL — a separate fetch from
/// `JobDetailNotifier` (testReport is its own Jenkins REST resource, not
/// embeddable in the job-detail `tree=` query). `null` data means no
/// published test report exists for this build, a normal state, not an
/// error.

abstract class _$TestReportNotifier extends $AsyncNotifier<TestReport?> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<TestReport?> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TestReport?>, TestReport?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TestReport?>, TestReport?>,
              AsyncValue<TestReport?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
