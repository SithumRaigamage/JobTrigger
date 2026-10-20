@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/flatten_jobs.dart';

import 'fixture_support.dart';

/// P11-05: lazy folder browsing and the recursive crawl against the real
/// fixture tree (`nested/level-2/…/level-7/deep-job`, `sample-multibranch`).
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test('lazy browsing reaches a job 7 folders deep (AUD-19)', () async {
    final repository = jenkins.adminRepository();
    var level = expectOk(await repository.fetchFolder(null));
    var folder = level.singleWhere((job) => job.name == 'nested');

    for (var depth = 2; depth <= 7; depth++) {
      // Each level is recognised as a folder by class, without its `jobs`.
      expect(folder.isFolder, isTrue, reason: folder.url);
      level = expectOk(await repository.fetchFolder(folder.url));
      if (depth == 7) break;
      folder = level.singleWhere((job) => job.name == 'level-$depth');
    }

    final deep = level.singleWhere((job) => job.name == 'level-7');
    final leaves = expectOk(await repository.fetchFolder(deep.url));
    expect(leaves.single.name, 'deep-job');
    expect(leaves.single.isFolder, isFalse);
    expect(leaves.single.url, startsWith(jenkins.url));
  });

  test(
    'multibranch is a folder, and branches show their display names',
    () async {
      final repository = jenkins.adminRepository();
      final root = expectOk(await repository.fetchFolder(null));
      final multibranch = root.singleWhere(
        (job) => job.name == 'sample-multibranch',
      );
      expect(multibranch.isFolder, isTrue);

      final branches = expectOk(await repository.fetchFolder(multibranch.url));
      final labels = branches.map((job) => job.label).toSet();
      expect(labels, containsAll(['main', 'feature/login']));
      final feature = branches.singleWhere(
        (job) => job.label == 'feature/login',
      );
      expect(feature.name, 'feature%2Flogin');
    },
  );

  test('the recursive crawl stops at the documented 6 levels', () async {
    final tree = expectOk(await jenkins.adminRepository().fetchJobTree());
    final names = flattenJobs(tree).map((job) => job.name).toSet();

    // Levels 1-6 of the nested chain are in the crawl...
    expect(names, containsAll(['nested', 'level-2', 'level-6']));
    // ...but not level-7's contents, which only lazy browsing reaches.
    expect(names, isNot(contains('deep-job')));
    // A crawled folder at the depth limit is still a folder (by class).
    final level6 = flattenJobs(tree).singleWhere((j) => j.name == 'level-6');
    expect(level6.isFolder, isTrue);
  });
}
