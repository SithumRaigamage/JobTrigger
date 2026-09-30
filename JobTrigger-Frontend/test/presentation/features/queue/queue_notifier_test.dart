import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/queue_entry.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/queue/queue_notifier.dart';

import '../../../support/fake_jenkins_repository.dart';

const _a = QueueEntry(id: 1, taskName: 'api', taskUrl: 'https://ci/job/api/');
const _b = QueueEntry(id: 2, taskName: 'web', taskUrl: 'https://ci/job/web/');

class _QueueRepository extends FakeJenkinsRepository {
  _QueueRepository(this.cancelResult);

  final Result<void, AppFailure> cancelResult;
  final cancelled = <int>[];

  /// What the queue holds on each fetch; the second fetch onwards can
  /// differ (e.g. the item started meanwhile).
  List<QueueEntry> queue = const [_a, _b];

  @override
  Future<Result<List<QueueEntry>, AppFailure>> fetchQueue() async => Ok(queue);

  @override
  Future<Result<void, AppFailure>> cancelQueueItem(int id) async {
    cancelled.add(id);
    return cancelResult;
  }
}

/// Replies with one fixed status (and optional JSON) for every request.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status, [this.body = '']);

  final int status;
  final String body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> _loaded(_QueueRepository repository) async {
  final container = ProviderContainer(
    overrides: [jenkinsRepositoryProvider.overrideWithValue(repository)],
  );
  // Disposed inside each test (see `_finish`), which also cancels the
  // queue's own 5s refresh timer.
  container
    ..listen(queueNotifierProvider, (_, _) {})
    ..listen(currentToastProvider, (_, _) {});
  await container.read(queueNotifierProvider.future);
  return container;
}

/// Lets the toast's 3.5s auto-dismiss run out, then disposes the container
/// (cancelling the queue refresh timer) before the test ends.
Future<void> _finish(WidgetTester tester, ProviderContainer container) async {
  await tester.pump(const Duration(seconds: 4));
  container.dispose();
}

void main() {
  group('QueueNotifier (US-JX-09)', () {
    testWidgets('cancel removes the item at once and confirms', (tester) async {
      final repository = _QueueRepository(const Ok(null));
      final container = await _loaded(repository);

      await container.read(queueNotifierProvider.notifier).cancel(_a);

      expect(repository.cancelled, [1]);
      expect(container.read(queueNotifierProvider).value!.map((e) => e.id), [
        2,
      ]);
      expect(container.read(currentToastProvider)?.title, 'Removed from queue');
      await _finish(tester, container);
    });

    testWidgets('a refused cancel restores the item and explains why', (
      tester,
    ) async {
      final repository = _QueueRepository(const Err(PermissionFailure()));
      final container = await _loaded(repository);

      await container.read(queueNotifierProvider.notifier).cancel(_a);

      expect(container.read(queueNotifierProvider).value!.map((e) => e.id), [
        1,
        2,
      ]);
      final toast = container.read(currentToastProvider);
      expect(toast?.type, ToastType.error);
      expect(toast?.message, const PermissionFailure().message);
      await _finish(tester, container);
    });
  });

  testWidgets('an item that already left the queue says so, not "removed"', (
    tester,
  ) async {
    final repository = _QueueRepository(const Err(ServerFailure(500)));
    final container = await _loaded(repository);
    repository.queue = const [_b]; // `api` started meanwhile.

    await container.read(queueNotifierProvider.notifier).cancel(_a);

    expect(container.read(queueNotifierProvider).value!.map((e) => e.id), [2]);
    expect(
      container.read(currentToastProvider)?.title,
      'Already left the queue',
    );
    await _finish(tester, container);
  });

  testWidgets('a 500 while the item is still queued is a real failure', (
    tester,
  ) async {
    final repository = _QueueRepository(const Err(ServerFailure(500)));
    final container = await _loaded(repository);

    await container.read(queueNotifierProvider.notifier).cancel(_a);

    expect(container.read(queueNotifierProvider).value!.map((e) => e.id), [
      1,
      2,
    ]);
    expect(container.read(currentToastProvider)?.title, 'Cancel failed');
    await _finish(tester, container);
  });

  group('JenkinsRepositoryImpl queue', () {
    JenkinsRepositoryImpl repo(_StatusAdapter adapter) => JenkinsRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://ci.test'))..httpClientAdapter = adapter,
    );

    test('fetchQueue parses items and rewrites task URLs', () async {
      final adapter = _StatusAdapter(
        200,
        '{"items":[{"id":184,"why":"In the quiet period","stuck":true,'
        '"inQueueSince":1790748388922,"task":{"name":"slow-build",'
        '"url":"http://jenkins.internal:8080/job/slow-build/",'
        '"color":"blue_anime"}}]}',
      );

      final items =
          (await repo(adapter).fetchQueue() as Ok<List<QueueEntry>, dynamic>)
              .value;

      expect(adapter.last?.path, '/queue/api/json');
      expect(items.single.id, 184);
      expect(items.single.taskUrl, 'https://ci.test/job/slow-build/');
      expect(items.single.stuck, isTrue);
      expect(items.single.why, 'In the quiet period');
      expect(items.single.inQueueSince, isNotNull);
    });

    test('cancel POSTs cancelItem?id= and treats 204 as success', () async {
      final adapter = _StatusAdapter(204);

      final result = await repo(adapter).cancelQueueItem(184);

      expect(adapter.last?.method, 'POST');
      expect(adapter.last?.path, '/queue/cancelItem');
      expect(adapter.last?.queryParameters, {'id': 184});
      expect(result, isA<Ok<void, AppFailure>>());
    });

    test(
      'stopping a pipeline build: the 302 Jenkins sends is success (AUD-39)',
      () async {
        final adapter = _StatusAdapter(302);

        final result = await repo(
          adapter,
        ).cancelBuild('https://ci.test/job/slow-build/7/');

        expect(adapter.last?.path, 'https://ci.test/job/slow-build/7/stop');
        expect(result, isA<Ok<void, AppFailure>>());
      },
    );

    test('an unknown item (404) is not reported as cancelled', () async {
      final result = await repo(_StatusAdapter(404)).cancelQueueItem(1);
      expect((result as Err<void, AppFailure>).error, isA<NotFoundFailure>());
    });

    test(
      "Jenkins' 422 for a user without permission is PermissionFailure",
      () async {
        final result = await repo(_StatusAdapter(422)).cancelQueueItem(1);
        expect(
          (result as Err<void, AppFailure>).error,
          isA<PermissionFailure>(),
        );
      },
    );
  });
}
