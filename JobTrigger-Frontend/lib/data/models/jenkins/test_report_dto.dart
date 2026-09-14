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
    @Default(<String>[])
    @JsonKey(
      name: 'suites',
      fromJson: _failingTestsFromJson,
      includeToJson: false,
    )
    List<String> failingTests,
  }) = _TestReportDto;

  factory TestReportDto.fromJson(Map<String, dynamic> json) =>
      _$TestReportDtoFromJson(json);
}

List<String> _failingTestsFromJson(dynamic rawSuites) {
  if (rawSuites is! List) return const [];
  final failing = <String>[];
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
      failing.add(className is String ? '$className.$name' : name);
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
