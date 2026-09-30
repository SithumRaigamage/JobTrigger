@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'fixture_support.dart';

/// P11-10 / US-JX-06: paging through a real job's full history
/// (`params-all` has well over one page of builds by now).
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test(
    'consecutive pages are contiguous, newest first, with no overlap',
    () async {
      final repository = jenkins.adminRepository();
      final url = jenkins.jobUrl('params-all');

      final first = expectOk(await repository.fetchJobHistory(url, count: 5));
      final second = expectOk(
        await repository.fetchJobHistory(url, start: 5, count: 5),
      );

      expect(first, hasLength(5));
      expect(second, hasLength(5));
      expect(first.last.number, second.first.number + 1);
      expect(
        first
            .map((b) => b.number)
            .toSet()
            .intersection(second.map((b) => b.number).toSet()),
        isEmpty,
      );
    },
  );

  test('past the end is an empty page, and causes carry the user id', () async {
    final repository = jenkins.adminRepository();
    final url = jenkins.jobUrl('params-all');

    final beyond = expectOk(
      await repository.fetchJobHistory(url, start: 5000, count: 20),
    );
    expect(beyond, isEmpty);

    final recent = expectOk(await repository.fetchJobHistory(url, count: 3));
    // Every fixture build is triggered by the admin API token.
    expect(recent.first.startedByUserIds, contains('admin'));
  });
}
