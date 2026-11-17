@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/html_text.dart';

import 'fixture_support.dart';

/// P11-18 / US-JX-14 round trips on a real build.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test('keep forever toggles and the description round-trips', () async {
    final repository = jenkins.adminRepository();
    final job = expectOk(
      await repository.fetchJobDetail(jenkins.jobUrl('freestyle-simple')),
    );
    final url = job.lastBuild!.url;
    final before = expectOk(await repository.fetchBuildDetail(url));
    expect(before.url, startsWith(jenkins.url));
    addTearDown(() async {
      final now = expectOk(await repository.fetchBuildDetail(url));
      if (now.keepLog != before.keepLog) await repository.toggleKeepLog(url);
      await repository.setBuildDescription(url, '');
    });

    expectOk(await repository.toggleKeepLog(url));
    final kept = expectOk(await repository.fetchBuildDetail(url));
    expect(kept.keepLog, !(before.keepLog ?? false));

    expectOk(await repository.setBuildDescription(url, '<b>Release</b> 9'));
    final described = expectOk(await repository.fetchBuildDetail(url));
    expect(described.description, '<b>Release</b> 9');
    expect(htmlToPlainText(described.description!), 'Release 9');
  });
}
