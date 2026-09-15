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
  final List<String> failingTests;
}
