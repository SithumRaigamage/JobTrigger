@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixture_support.dart';

/// P11-21 / US-JX-17 against the seeded "Pipelines" list view.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test('lists views, primary first, and a view lists only its jobs', () async {
    final repository = jenkins.adminRepository();
    final views = expectOk(await repository.fetchViews());

    expect(views.first.isPrimary, isTrue);
    expect(views.first.label, 'All jobs');
    final pipelines = views.singleWhere((view) => view.name == 'Pipelines');
    expect(pipelines.url, '${jenkins.url}/view/Pipelines/');

    final jobs = expectOk(await repository.fetchFolder(pipelines.url));
    expect(jobs.map((job) => job.name).toSet(), {
      'pipeline-input-params',
      'pipeline-input-simple',
      'pipeline-stages',
    });
  });
}
