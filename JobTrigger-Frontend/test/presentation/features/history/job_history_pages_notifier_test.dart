import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/history_filter.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/history/job_history_pages_notifier.dart';
import 'package:job_trigger/presentation/features/history/job_history_screen.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';

import '../../../support/fake_jenkins_repository.dart';

const _job = 'https://ci.test/job/api/';

/// [total] builds, newest first, served in pages; odd numbers failed.
class _PagedRepository extends FakeJenkinsRepository {
  _PagedRepository(this.total);

  final int total;
  final starts = <int>[];
  bool failNext = false;

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) async {
    starts.add(start);
    if (failNext) return const Err(NetworkFailure());
    return Ok([
      for (var i = start; i < start + count && i < total; i++)
        JenkinsBuild(
          number: total - i,
          url: '$_job${total - i}/',
          result: (total - i).isOdd ? 'FAILURE' : 'SUCCESS',
          timestamp: 0,
        ),
    ]);
  }
}

ProviderContainer _container(_PagedRepository repository) {
  final container = ProviderContainer(
    overrides: [jenkinsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container.listen(jobHistoryPagesNotifierProvider(_job), (_, _) {});
  return container;
}

void main() {
  test('loads page after page until a short page ends history', () async {
    final repository = _PagedRepository(45);
    final container = _container(repository);
    final notifier = container.read(
      jobHistoryPagesNotifierProvider(_job).notifier,
    );

    var pages = await container.read(
      jobHistoryPagesNotifierProvider(_job).future,
    );
    expect(pages.builds, hasLength(20));
    expect(pages.hasMore, isTrue);

    await notifier.loadMore();
    await notifier.loadMore();
    pages = container.read(jobHistoryPagesNotifierProvider(_job)).requireValue;

    expect(repository.starts, [0, 20, 40]);
    expect(pages.builds, hasLength(45));
    expect(pages.builds.first.number, 45);
    expect(pages.builds.last.number, 1);
    expect(pages.hasMore, isFalse);

    await notifier.loadMore();
    expect(repository.starts, hasLength(3), reason: 'nothing past the end');
  });

  test('a failed page keeps what is loaded and stops paging', () async {
    final repository = _PagedRepository(100);
    final container = _container(repository);
    await container.read(jobHistoryPagesNotifierProvider(_job).future);

    repository.failNext = true;
    await container
        .read(jobHistoryPagesNotifierProvider(_job).notifier)
        .loadMore();

    final pages = container
        .read(jobHistoryPagesNotifierProvider(_job))
        .requireValue;
    expect(pages.builds, hasLength(20));
    expect(pages.hasMore, isFalse);
    expect(pages.isLoadingMore, isFalse);
  });

  group('JobHistoryScreen', () {
    Future<void> pump(WidgetTester tester, int total) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            jenkinsRepositoryProvider.overrideWithValue(
              _PagedRepository(total),
            ),
            activeServerNotifierProvider.overrideWith(_Server.new),
          ],
          child: const MaterialApp(
            home: JobHistoryScreen(
              job: JenkinsJob(name: 'api', url: _job),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('filter chips narrow the list', (tester) async {
      await pump(tester, 4);
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Failed'));
      await tester.pumpAndSettle();

      expect(find.text('#4'), findsNothing);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('End of history · 4 builds'), findsOneWidget);
    });

    testWidgets('when a filter hides every loaded build, offers to dig back', (
      tester,
    ) async {
      await pump(tester, 60);
      await tester.tap(find.widgetWithText(FilterChip, 'Started by me'));
      await tester.pumpAndSettle();

      expect(find.text('No matching builds in the last 20'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
    });
  });
}

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 's',
    serverName: 's',
    jenkinsURL: 'https://ci.test',
    username: 'alice',
    secret: 'x',
  );
}
