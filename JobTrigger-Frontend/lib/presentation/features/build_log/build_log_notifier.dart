import 'dart:async';
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/console_decoder.dart';
import '../../../domain/jenkins/log_chunk.dart';

part 'build_log_notifier.g.dart';

/// At most this many lines are kept in memory (US-JX-07, AUD-12). Older
/// lines are dropped from the front; "Save full log" has everything.
const maxConsoleLines = 20000;

/// A log bigger than this opens at its tail rather than downloading the
/// whole thing first (a real fixture log is 14.7 MB).
const initialTailBytes = 1024 * 1024;

/// What the console shows (US-JX-07).
class ConsoleState {
  const ConsoleState({
    required this.lines,
    this.pendingLine,
    this.droppedLines = 0,
    this.startsMidLog = false,
    this.streaming = false,
    this.reconnecting = false,
  });

  /// Completed, decoded lines, oldest first, capped at [maxConsoleLines].
  final List<ConsoleLine> lines;

  /// The line the build is still writing, if any.
  final ConsoleLine? pendingLine;

  /// Lines dropped from the front to respect [maxConsoleLines].
  final int droppedLines;

  /// The log was opened at its tail, so earlier output was never loaded.
  final bool startsMidLog;

  /// Jenkins reports more output coming (`X-More-Data`).
  final bool streaming;

  /// The last poll failed. The log stays visible while polling retries
  /// with backoff (AUD-13).
  final bool reconnecting;

  /// Earlier output isn't shown, whether never loaded or dropped.
  bool get isPartial => startsMidLog || droppedLines > 0;

  /// Every line on screen, including the one still being written.
  List<ConsoleLine> get visibleLines => [...lines, ?pendingLine];
}

/// Streams a build's console via Jenkins' progressive-text API, family-keyed
/// by the build's absolute URL (US-LOG-01, rewritten for US-JX-07).
///
/// Each chunk is decoded exactly once by a [ConsoleDecoder], which carries
/// partial lines, escapes, and style across chunks. That replaces
/// re-sanitizing and re-splitting the whole log every second (AUD-12). A
/// failed poll keeps what's on screen and retries with backoff (AUD-13).
/// Timers are cancelled in `ref.onDispose`, the same leak discipline as
/// `BuildStatusPollingNotifier` (P5-06).
@riverpod
class BuildLogNotifier extends _$BuildLogNotifier {
  static const _pollEvery = Duration(seconds: 1);
  static const _maxBackoff = Duration(seconds: 15);

  final _decoder = ConsoleDecoder();
  final List<ConsoleLine> _lines = [];
  Timer? _timer;
  int _offset = 0;
  int _droppedLines = 0;
  int _failures = 0;
  bool _startsMidLog = false;

  @override
  Future<ConsoleState> build(String buildUrl) async {
    ref.onDispose(() => _timer?.cancel());
    final repository = ref.read(jenkinsRepositoryProvider);

    // Size first (a HEAD, no body), so a huge log opens at its tail.
    final size = await repository.fetchLogSize(buildUrl);
    final start = switch (size) {
      Ok(:final value) when value > initialTailBytes =>
        value - initialTailBytes,
      _ => 0,
    };
    _startsMidLog = start > 0;

    final result = await repository.streamBuildLog(buildUrl, start: start);
    final chunk = result.fold((chunk) => chunk, (failure) => throw failure);
    var text = chunk.text;
    if (_startsMidLog) {
      // Starting mid-log almost always lands mid-line: drop that fragment.
      final firstBreak = text.indexOf('\n');
      text = firstBreak == -1 ? '' : text.substring(firstBreak + 1);
    }
    return _apply(chunk, text);
  }

  ConsoleState _apply(LogChunk chunk, String text) {
    _offset = chunk.nextOffset;
    _lines.addAll(_decoder.addChunk(text));
    final overflow = _lines.length - maxConsoleLines;
    if (overflow > 0) {
      _lines.removeRange(0, overflow);
      _droppedLines += overflow;
    }
    if (chunk.hasMoreData) _schedule(_pollEvery);
    return ConsoleState(
      lines: List.unmodifiable(_lines),
      pendingLine: _decoder.pendingLine,
      droppedLines: _droppedLines,
      startsMidLog: _startsMidLog,
      streaming: chunk.hasMoreData,
    );
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _poll);
  }

  Future<void> _poll() async {
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .streamBuildLog(buildUrl, start: _offset);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        _failures = 0;
        state = AsyncData(_apply(value, value.text));
      case Err():
        // Keep the log; say we're reconnecting; back off 1, 2, 4, 8, 15s.
        _failures++;
        final current = state.value;
        if (current != null) {
          state = AsyncData(
            ConsoleState(
              lines: current.lines,
              pendingLine: current.pendingLine,
              droppedLines: current.droppedLines,
              startsMidLog: current.startsMidLog,
              streaming: true,
              reconnecting: true,
            ),
          );
        }
        final backoff = Duration(
          seconds: math.min(
            1 << (_failures - 1).clamp(0, 4),
            _maxBackoff.inSeconds,
          ),
        );
        _schedule(backoff);
    }
  }
}
