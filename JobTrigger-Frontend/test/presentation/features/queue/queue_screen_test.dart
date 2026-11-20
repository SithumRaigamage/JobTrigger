import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/queue_entry.dart';
import 'package:job_trigger/presentation/features/queue/queue_screen.dart';

import '../../../support/fake_jenkins_repository.dart';

// Widget coverage for the US-JX-09 queue screen (pre-release audit
// 2026-11-20: the screen itself had no widget test, only its notifier).

final _waiting = QueueEntry(
  id: 7,
  taskName: 'deploy-api',
  taskUrl: 'https://ci.test/job/deploy-api/',
  why: 'Waiting for next available executor',
  inQueueSince: DateTime.now().subtract(const Duration(minutes: 2)),
);

const _stuck = QueueEntry(
  id: 8,
  taskName: 'nightly',
  taskUrl: 'https://ci.test/job/nightly/',
  why: 'There are no nodes with the label ‘arm64’',
  stuck: true,
);

class _Repo extends FakeJenkinsRepository {
  _Repo(this.queue);

  Result<List<QueueEntry>, AppFailure> queue;
  final cancelled = <int>[];
  int fetches = 0;

  @override
  Future<Result<List<QueueEntry>, AppFailure>> fetchQueue() async {
    fetches++;
    return queue;
  }

  @override
  Future<Result<void, AppFailure>> cancelQueueItem(int id) async {
    cancelled.add(id);
    return const Ok(null);
  }
}

Future<_Repo> _pump(
  WidgetTester tester,
  Result<List<QueueEntry>, AppFailure> queue,
) async {
  final repo = _Repo(queue);
  tester.view
    ..physicalSize = const Size(900, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: QueueScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Disposes the screen inside the test so the 5 s refresh timer is cancelled.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  group('QueueScreen (US-JX-09)', () {
    testWidgets('lists queued builds with position, reason and stuck flag', (
      tester,
    ) async {
      await _pump(tester, Ok([_waiting, _stuck]));

      expect(find.text('Build queue'), findsOneWidget);
      expect(
        find.text('2 builds waiting · refreshes every 5s'),
        findsOneWidget,
      );
      expect(find.text('deploy-api'), findsOneWidget);
      expect(find.text('Waiting for next available executor'), findsOneWidget);
      expect(find.textContaining('in queue '), findsOneWidget);
      expect(find.text('nightly'), findsOneWidget);
      // Icon + text, never colour alone (NFR-A11Y-03).
      expect(find.text(' Stuck'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('an empty queue says so', (tester) async {
      await _pump(tester, const Ok([]));

      expect(find.text('Nothing waiting · refreshes every 5s'), findsOneWidget);
      expect(find.text('Nothing is waiting'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('a single build uses the singular', (tester) async {
      await _pump(tester, Ok([_waiting]));

      expect(find.text('1 build waiting · refreshes every 5s'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('a failure shows the error view and Retry fetches again', (
      tester,
    ) async {
      final repo = await _pump(tester, const Err(NetworkFailure()));

      expect(find.text('Retry Connection'), findsOneWidget);
      final before = repo.fetches;

      repo.queue = Ok([_waiting]);
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(repo.fetches, greaterThan(before));
      expect(find.text('deploy-api'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('cancel asks first; Remove cancels that item only', (
      tester,
    ) async {
      final repo = await _pump(tester, Ok([_waiting, _stuck]));

      await tester.tap(find.byTooltip('Cancel deploy-api'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from queue?'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(repo.cancelled, [7]);
      expect(find.text('deploy-api'), findsNothing);
      expect(find.text('nightly'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4)); // toast
      await _dispose(tester);
    });

    testWidgets('dismissing the confirmation cancels nothing', (tester) async {
      final repo = await _pump(tester, Ok([_waiting]));

      await tester.tap(find.byTooltip('Cancel deploy-api'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.cancelled, isEmpty);
      expect(find.text('deploy-api'), findsOneWidget);
      await _dispose(tester);
    });
  });
}
