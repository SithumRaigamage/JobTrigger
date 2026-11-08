import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_node.dart';
import 'package:job_trigger/domain/jenkins/queue_entry.dart';
import 'package:job_trigger/presentation/features/nodes/nodes_notifier.dart';
import 'package:job_trigger/presentation/features/queue/queue_notifier.dart';

import '../../../support/fake_jenkins_repository.dart';

// P19-05: the auto-refresh timer used to start before the fetch, so a
// request slower than the interval (an unreachable Jenkins takes the full
// 15s connect timeout) was restarted every 5s/10s and never got to fail.
// The Queue and Nodes screens then spun forever instead of showing the error.

class _Repository extends FakeJenkinsRepository {
  /// How long each request takes; null fails at once.
  Duration? latency;
  int queueCalls = 0;
  int nodesCalls = 0;

  Future<Result<T, AppFailure>> _answer<T>(T value) async {
    final wait = latency;
    if (wait == null) return const Err(NetworkFailure());
    await Future<void>.delayed(wait);
    return Ok(value);
  }

  @override
  Future<Result<List<QueueEntry>, AppFailure>> fetchQueue() {
    queueCalls++;
    return _answer(const <QueueEntry>[]);
  }

  @override
  Future<Result<List<JenkinsNode>, AppFailure>> fetchNodes() {
    nodesCalls++;
    return _answer(const <JenkinsNode>[]);
  }
}

/// Runs [body] on the test's fake clock with a default container (no
/// `retry:` override, so the providers' own opt-out is what's tested).
Future<void> _scenario(
  WidgetTester tester,
  _Repository repo,
  Future<void> Function(ProviderContainer container) body,
) async {
  final container = ProviderContainer(
    overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
  );
  container
    ..listen(queueNotifierProvider, (_, _) {})
    ..listen(nodesNotifierProvider, (_, _) {});
  await tester.pump();
  await body(container);
  container.dispose();
}

void main() {
  group('a request slower than the refresh interval', () {
    testWidgets('Queue is not restarted before it answers', (tester) async {
      final repo = _Repository()..latency = const Duration(seconds: 8);
      await _scenario(tester, repo, (container) async {
        await tester.pump(const Duration(seconds: 7));
        expect(repo.queueCalls, 1, reason: 'one request still in flight');

        await tester.pump(const Duration(seconds: 1));
        expect(container.read(queueNotifierProvider).hasValue, isTrue);
      });
    });

    testWidgets('Nodes is not restarted before it answers', (tester) async {
      final repo = _Repository()..latency = const Duration(seconds: 12);
      await _scenario(tester, repo, (container) async {
        await tester.pump(const Duration(seconds: 11));
        expect(repo.nodesCalls, 1, reason: 'one request still in flight');

        await tester.pump(const Duration(seconds: 1));
        expect(container.read(nodesNotifierProvider).hasValue, isTrue);
      });
    });
  });

  group('after a successful fetch', () {
    testWidgets('Queue refreshes 5s later', (tester) async {
      final repo = _Repository()..latency = const Duration(seconds: 1);
      await _scenario(tester, repo, (container) async {
        await tester.pump(const Duration(seconds: 5));
        expect(repo.queueCalls, 1);

        await tester.pump(const Duration(seconds: 2));
        expect(repo.queueCalls, 2);
        // Let the refresh in flight finish before the container goes.
        await tester.pump(const Duration(seconds: 2));
      });
    });

    testWidgets('Nodes refreshes 10s later', (tester) async {
      final repo = _Repository()..latency = const Duration(seconds: 1);
      await _scenario(tester, repo, (container) async {
        await tester.pump(const Duration(seconds: 10));
        expect(repo.nodesCalls, 1);

        await tester.pump(const Duration(seconds: 2));
        expect(repo.nodesCalls, 2);
        // Let the refresh in flight finish before the container goes.
        await tester.pump(const Duration(seconds: 2));
      });
    });
  });

  group('a failed fetch', () {
    testWidgets('Queue shows the error once and stops, with no retry loop', (
      tester,
    ) async {
      final repo = _Repository();
      await _scenario(tester, repo, (container) async {
        await tester.pump(const Duration(minutes: 1));

        expect(repo.queueCalls, 1);
        expect(
          container.read(queueNotifierProvider).error,
          isA<NetworkFailure>(),
        );
      });
    });

    testWidgets('Nodes shows the error once and stops, with no retry loop', (
      tester,
    ) async {
      final repo = _Repository();
      await _scenario(tester, repo, (container) async {
        await tester.pump(const Duration(minutes: 1));

        expect(repo.nodesCalls, 1);
        expect(
          container.read(nodesNotifierProvider).error,
          isA<NetworkFailure>(),
        );
      });
    });
  });
}
