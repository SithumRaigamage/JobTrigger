@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';

import 'fixture_support.dart';

/// P11-17 / US-JX-13 against the real server.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test('disable, refused trigger, enable', () async {
    final repository = jenkins.adminRepository();
    final url = jenkins.jobUrl('freestyle-simple');
    addTearDown(() => repository.setJobEnabled(url, enabled: true));

    expectOk(await repository.setJobEnabled(url, enabled: false));
    expect(expectOk(await repository.fetchJobDetail(url)).buildable, isFalse);

    final trigger = await repository.triggerBuild(url, isParameterized: false);
    expect(
      (trigger as Err<String?, AppFailure>).error,
      isA<JobDisabledFailure>(),
    );

    expectOk(await repository.setJobEnabled(url, enabled: true));
    expect(expectOk(await repository.fetchJobDetail(url)).buildable, isTrue);
  });

  test(
    'a read-only user and a multibranch branch are both refused (403)',
    () async {
      final viewer = await jenkins.viewerRepository().setJobEnabled(
        jenkins.jobUrl('freestyle-simple'),
        enabled: false,
      );
      expect((viewer as Err<void, AppFailure>).error, isA<PermissionFailure>());

      final branch = await jenkins.adminRepository().setJobEnabled(
        jenkins.jobUrl('sample-multibranch/main'),
        enabled: false,
      );
      expect((branch as Err<void, AppFailure>).error, isA<PermissionFailure>());
    },
  );
}
