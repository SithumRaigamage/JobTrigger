@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/jenkins/branch_kind.dart';

import 'fixture_support.dart';

/// P11-07 / US-JX-03 against `sample-multibranch` (branches `main` and
/// `feature/login`, tag `v1.0.0`).
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  String projectUrl() => jenkins.jobUrl('sample-multibranch');

  test('classifies branches and tags from the project views', () async {
    final kinds = expectOk(
      await jenkins.adminRepository().fetchBranchKinds(projectUrl()),
    );
    expect(kinds['main'], BranchKind.branch);
    expect(kinds['feature%2Flogin'], BranchKind.branch);
    expect(kinds['v1.0.0'], BranchKind.tag);
  });

  test('scan now is accepted and its log reports completion', () async {
    final repository = jenkins.adminRepository();
    expectOk(await repository.scanMultibranch(projectUrl()));

    final log = await pollUntil(() async {
      final chunk = expectOk(
        await repository.streamBuildLog('${projectUrl()}indexing/'),
      );
      return chunk.hasMoreData ? null : chunk.text;
    }, description: 'the scan to finish');
    expect(log, contains('Finished branch indexing'));
  });

  test('a read-only user gets PermissionFailure, not AuthFailure', () async {
    final result = await jenkins.viewerRepository().scanMultibranch(
      projectUrl(),
    );
    expect((result as Err<void, AppFailure>).error, isA<PermissionFailure>());
  });
}
