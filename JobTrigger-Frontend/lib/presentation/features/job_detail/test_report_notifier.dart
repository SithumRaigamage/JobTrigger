import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/test_report.dart';

part 'test_report_notifier.g.dart';

/// US-PIPE-06. Family-keyed by build URL — a separate fetch from
/// `JobDetailNotifier` (testReport is its own Jenkins REST resource, not
/// embeddable in the job-detail `tree=` query). `null` data means no
/// published test report exists for this build, a normal state, not an
/// error.
@riverpod
class TestReportNotifier extends _$TestReportNotifier {
  @override
  Future<TestReport?> build(String buildUrl) async {
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchTestReport(buildUrl);
    return result.fold((report) => report, (failure) => throw failure);
  }
}
