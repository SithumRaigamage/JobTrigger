import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/branch_kind.dart';

void main() {
  test('maps the branch-api view names', () {
    expect(BranchKind.forView('default'), BranchKind.branch);
    expect(BranchKind.forView('change-requests'), BranchKind.pullRequest);
    expect(BranchKind.forView('tags'), BranchKind.tag);
    expect(BranchKind.forView('anything-else'), BranchKind.branch);
  });

  test('classifies each job, preferring the more specific view', () {
    final kinds = branchKindsFromViews({
      'default': ['main', 'feature%2Flogin', 'PR-7'],
      'change-requests': ['PR-7'],
      'tags': ['v1.0.0'],
    });

    expect(kinds, {
      'main': BranchKind.branch,
      'feature%2Flogin': BranchKind.branch,
      'PR-7': BranchKind.pullRequest,
      'v1.0.0': BranchKind.tag,
    });
  });
}
