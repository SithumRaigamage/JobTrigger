@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixture_support.dart';

/// P11-12 / US-JX-08 against `junit-report` (pass, fail with a stack
/// trace, skip).
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test('failing cases carry the message and stack trace', () async {
    final repository = jenkins.adminRepository();
    final job = expectOk(
      await repository.fetchJobDetail(jenkins.jobUrl('junit-report')),
    );
    final report = expectOk(
      await repository.fetchTestReport(job.lastBuild!.url),
    )!;

    expect(report.failCount, 1);
    final divides = report.failingTests.single;
    expect(divides.displayName, 'com.jobtrigger.CalcTest.divides');
    expect(divides.errorDetails, 'expected:<2> but was:<3>');
    expect(divides.stackTrace, contains('CalcTest.java:42'));
  });
}
