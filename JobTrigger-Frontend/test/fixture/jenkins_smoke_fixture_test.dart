@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/jenkins/flatten_jobs.dart';

import 'fixture_support.dart';

/// Baseline: the production client reaches the fixture, rewrites Jenkins'
/// deliberately-wrong configured URL, and permission errors map correctly.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped, and the
  // environment only exists under `fixture.sh test`.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test(
    'fetches the job tree and rewrites every URL to the active server',
    () async {
      final jobs = expectOk(await jenkins.adminRepository().fetchJobTree());

      final names = jobs.map((job) => job.name).toSet();
      expect(names, containsAll(['freestyle-simple', 'params-all', 'nested']));
      // casc.yaml sets Jenkins' own URL to http://jenkins.internal:8080/.
      for (final job in flattenJobs(jobs)) {
        expect(job.url, startsWith(jenkins.url), reason: job.name);
        if (job.lastBuild != null) {
          expect(job.lastBuild!.url, startsWith(jenkins.url), reason: job.name);
        }
      }
    },
  );

  test('triggers a build with the CSRF crumb and session cookie', () async {
    final build = await triggerAndAwaitStart(jenkins, 'freestyle-simple');
    final finished = await awaitCompletion(
      jenkins,
      'freestyle-simple',
      build.number,
    );
    expect(finished.result, 'SUCCESS');
  });

  test('a read-only user gets AuthFailure when triggering', () async {
    final result = await jenkins.viewerRepository().triggerBuild(
      jenkins.jobUrl('freestyle-simple'),
      isParameterized: false,
    );
    expect(result, isA<Err<String?, AppFailure>>());
    expect((result as Err).error, isA<AuthFailure>());
  });
}
