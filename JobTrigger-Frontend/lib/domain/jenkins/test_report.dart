/// A build's test result summary (US-PIPE-06) — `{buildURL}/testReport/`.
/// `null` at the call site (not this type) means "no test report exists
/// for this build," a normal state (the job doesn't publish test results,
/// or this build hasn't finished), not an error.
class TestReport {
  const TestReport({
    required this.passCount,
    required this.failCount,
    required this.skipCount,
    this.failingTests = const [],
  });

  final int passCount;
  final int failCount;
  final int skipCount;

  /// `ClassName.testName` for each failed/regressed case — a summary list,
  /// not full stack traces/output (those stay in the console log, US-LOG-01).
  final List<FailingTest> failingTests;
}

/// One failing test case with why it failed (US-JX-08).
class FailingTest {
  const FailingTest({
    required this.name,
    this.className,
    this.errorDetails,
    this.stackTrace,
    this.durationSeconds,
    this.isNewFailure = false,
  });

  final String name;
  final String? className;

  /// The assertion or exception message.
  final String? errorDetails;
  final String? stackTrace;
  final double? durationSeconds;

  /// Failing for the first time: Jenkins' `REGRESSION` status (it passed
  /// last build) or `age == 1`.
  final bool isNewFailure;

  /// `ClassName.testName`, how the summary lists it.
  String get displayName => className == null ? name : '$className.$name';
}
