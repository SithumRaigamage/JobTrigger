import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/features/build_log/build_log_notifier.dart';

import '../../../support/fake_jenkins_repository.dart';

const _buildUrl = 'https://jenkins.test/job/demo/1/';

/// Serves scripted results by call order and records each `start`.
class _ScriptedRepository extends FakeJenkinsRepository {
  _ScriptedRepository(this._results, {this.size = 100});

  final List<Result<LogChunk, AppFailure>> _results;
  final int size;
  final starts = <int>[];
  int _call = 0;

  @override
  Future<Result<int, AppFailure>> fetchLogSize(String buildUrl) async =>
      Ok(size);

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) async {
    starts.add(start);
    final result = _results[_call];
    if (_call < _results.length - 1) _call++;
    return result;
  }
}

Ok<LogChunk, AppFailure> _chunk(String text, int next, {bool more = false}) =>
    Ok(LogChunk(text: text, nextOffset: next, hasMoreData: more));

ProviderContainer _container(_ScriptedRepository repository) {
  final container = ProviderContainer(
    overrides: [jenkinsRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container.listen(buildLogNotifierProvider(_buildUrl), (_, _) {});
  return container;
}

List<String> _texts(ConsoleState state) => [
  for (final line in state.visibleLines) line.text,
];

void main() {
  test('a small log is read from offset 0 and stops when complete', () async {
    final repository = _ScriptedRepository([_chunk('one\ntwo\n', 8)]);
    final container = _container(repository);

    final state = await container.read(
      buildLogNotifierProvider(_buildUrl).future,
    );

    expect(repository.starts, [0]);
    expect(_texts(state), ['one', 'two']);
    expect(state.streaming, isFalse);
    expect(state.isPartial, isFalse);
  });

  test('a huge log opens at its tail and drops the leading fragment', () async {
    const size = initialTailBytes * 5;
    final repository = _ScriptedRepository([
      _chunk('ment of a cut line\nfirst whole line\nlast\n', size),
    ], size: size);
    final container = _container(repository);

    final state = await container.read(
      buildLogNotifierProvider(_buildUrl).future,
    );

    expect(repository.starts, [size - initialTailBytes]);
    expect(_texts(state), ['first whole line', 'last']);
    expect(state.startsMidLog, isTrue);
  });

  testWidgets('streams chunks, carrying a line split across them', (
    tester,
  ) async {
    final repository = _ScriptedRepository([
      _chunk('compil', 6, more: true),
      _chunk('ing\ndone\n', 15),
    ]);
    final container = _container(repository);
    await tester.pump();

    var state = container.read(buildLogNotifierProvider(_buildUrl)).value!;
    expect(state.lines, isEmpty);
    expect(state.pendingLine?.text, 'compil');

    await tester.pump(const Duration(seconds: 1));
    state = container.read(buildLogNotifierProvider(_buildUrl)).value!;
    expect(repository.starts, [0, 6]);
    expect(_texts(state), ['compiling', 'done']);
    expect(state.streaming, isFalse);
  });

  testWidgets('a failed poll keeps the log and retries with backoff (AUD-13)', (
    tester,
  ) async {
    final repository = _ScriptedRepository([
      _chunk('kept\n', 5, more: true),
      const Err(NetworkFailure()),
      const Err(NetworkFailure()),
      _chunk('back\n', 10),
    ]);
    final container = _container(repository);
    await tester.pump();

    await tester.pump(const Duration(seconds: 1)); // first failure
    var state = container.read(buildLogNotifierProvider(_buildUrl)).value!;
    expect(state.reconnecting, isTrue);
    expect(_texts(state), ['kept'], reason: 'the log stays on screen');

    await tester.pump(const Duration(seconds: 1)); // retry after 1s: fails
    expect(repository.starts, [0, 5, 5]);
    await tester.pump(const Duration(seconds: 1));
    expect(repository.starts, hasLength(3), reason: 'backoff doubled to 2s');
    await tester.pump(const Duration(seconds: 1));

    state = container.read(buildLogNotifierProvider(_buildUrl)).value!;
    expect(repository.starts, [0, 5, 5, 5]);
    expect(state.reconnecting, isFalse);
    expect(_texts(state), ['kept', 'back']);
  });

  test('keeps at most maxConsoleLines, counting what was dropped', () async {
    final text = StringBuffer();
    for (var i = 0; i < maxConsoleLines + 250; i++) {
      text.writeln('line $i');
    }
    final repository = _ScriptedRepository([
      _chunk(text.toString(), text.length),
    ]);
    final container = _container(repository);

    final state = await container.read(
      buildLogNotifierProvider(_buildUrl).future,
    );

    expect(state.lines, hasLength(maxConsoleLines));
    expect(state.droppedLines, 250);
    expect(state.lines.first.text, 'line 250');
    expect(state.isPartial, isTrue);
  });
}
