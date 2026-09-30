import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/test_report.dart';

part 'test_report_dto.freezed.dart';
part 'test_report_dto.g.dart';

/// `GET {buildURL}/testReport/api/json?tree=passCount,failCount,skipCount,
/// suites[cases[className,name,status]]` (US-PIPE-06). A 404 here (no
/// published test results) is handled in `JenkinsRepositoryImpl
/// .fetchTestReport` as "no report," not parsed by this DTO at all.
@freezed
abstract class TestReportDto with _$TestReportDto {
  const factory TestReportDto({
    @Default(0) int passCount,
    @Default(0) int failCount,
    @Default(0) int skipCount,
    // `suites[].cases[]` is polymorphic-in-depth (nested test suites, each
    // holding individual cases) -- flatten straight to the
    // `ClassName.testName` strings actually rendered, same reasoning as
    // `causes`/`changes` on `JenkinsBuildDto`.
    @Default(<FailingTest>[])
    @JsonKey(
      name: 'suites',
      fromJson: _failingTestsFromJson,
      includeToJson: false,
    )
    List<FailingTest> failingTests,
  }) = _TestReportDto;

  factory TestReportDto.fromJson(Map<String, dynamic> json) =>
      _$TestReportDtoFromJson(json);
}

List<FailingTest> _failingTestsFromJson(dynamic rawSuites) {
  if (rawSuites is! List) return const [];
  final failing = <FailingTest>[];
  for (final suite in rawSuites) {
    if (suite is! Map<String, dynamic>) continue;
    final cases = suite['cases'];
    if (cases is! List) continue;
    for (final testCase in cases) {
      if (testCase is! Map<String, dynamic>) continue;
      // FAILED: never passed. REGRESSION: previously passing, now failing.
      // Both read as "currently failing" to the user.
      final status = testCase['status'];
      if (status != 'FAILED' && status != 'REGRESSION') continue;
      final name = testCase['name'];
      if (name is! String) continue;
      final className = testCase['className'];
      final age = testCase['age'];
      final duration = testCase['duration'];
      failing.add(
        FailingTest(
          name: name,
          className: className is String ? className : null,
          errorDetails: testCase['errorDetails'] as String?,
          stackTrace: testCase['errorStackTrace'] as String?,
          durationSeconds: duration is num ? duration.toDouble() : null,
          isNewFailure: status == 'REGRESSION' || age == 1,
        ),
      );
    }
  }
  return failing;
}

extension TestReportDtoX on TestReportDto {
  TestReport toDomain() => TestReport(
    passCount: passCount,
    failCount: failCount,
    skipCount: skipCount,
    failingTests: failingTests,
  );
}
