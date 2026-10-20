@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';

import 'fixture_support.dart';

/// P11-13 / US-JX-09: a real queued item on `slow-build` (no concurrent
/// builds, so a second trigger has to wait).
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test(
    'a waiting build is listed with its reason, and can be cancelled',
    () async {
      final repository = jenkins.adminRepository();
      final job = jenkins.jobUrl('slow-build');
      final running = await triggerAndAwaitStart(jenkins, 'slow-build');
      expectOk(await repository.triggerBuild(job, isParameterized: false));

      final entry = await pollUntil(() async {
        final queue = expectOk(await repository.fetchQueue());
        final waiting = queue.where((e) => e.taskName == 'slow-build');
        return waiting.isEmpty ? null : waiting.first;
      }, description: 'slow-build to be queued');
      expect(entry.taskUrl, startsWith(jenkins.url));
      expect(entry.why, isNotNull);

      // A read-only user is refused -- Jenkins says 422, not 403.
      final refused = await jenkins.viewerRepository().cancelQueueItem(
        entry.id,
      );
      expect(
        (refused as Err<void, AppFailure>).error,
        isA<PermissionFailure>(),
      );

      expectOk(await repository.cancelQueueItem(entry.id));
      final after = expectOk(await repository.fetchQueue());
      expect(after.where((e) => e.id == entry.id), isEmpty);

      // Cancelling again: Jenkins answers a bare 500 ("not cancellable"),
      // which the app must not report as "removed".
      final again = await repository.cancelQueueItem(entry.id);
      expect((again as Err<void, AppFailure>).error, isA<ServerFailure>());

      expectOk(await repository.cancelBuild(running.url));
    },
  );
}
