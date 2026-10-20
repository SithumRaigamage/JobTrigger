import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/console_decoder.dart';
import '../../common_widgets/toast_controller.dart';
import 'build_log_notifier.dart';
import '../../../core/platform/temp_files.dart';

part 'console_notifiers.g.dart';

/// Console display preferences (US-JX-07). Not secret, so they live in
/// `shared_preferences`, like the theme.
class ConsolePrefs {
  const ConsolePrefs({
    this.wrap = true,
    this.fontStep = 1,
    this.timestamps = false,
  });

  /// Wrap long lines (true) or scroll horizontally (false).
  final bool wrap;

  /// 0 small, 1 normal, 2 large.
  final int fontStep;
  final bool timestamps;

  static const fontSizes = [10.0, 12.0, 14.0];

  double get fontSize => fontSizes[fontStep.clamp(0, 2)];

  ConsolePrefs copyWith({bool? wrap, int? fontStep, bool? timestamps}) =>
      ConsolePrefs(
        wrap: wrap ?? this.wrap,
        fontStep: fontStep ?? this.fontStep,
        timestamps: timestamps ?? this.timestamps,
      );
}

@riverpod
class ConsolePrefsNotifier extends _$ConsolePrefsNotifier {
  static const _wrapKey = 'console_wrap';
  static const _fontKey = 'console_font_step';
  static const _timestampsKey = 'console_timestamps';

  @override
  ConsolePrefs build() {
    _load();
    return const ConsolePrefs();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = ConsolePrefs(
      wrap: prefs.getBool(_wrapKey) ?? true,
      fontStep: prefs.getInt(_fontKey) ?? 1,
      timestamps: prefs.getBool(_timestampsKey) ?? false,
    );
  }

  Future<void> update(ConsolePrefs next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wrapKey, next.wrap);
    await prefs.setInt(_fontKey, next.fontStep);
    await prefs.setBool(_timestampsKey, next.timestamps);
  }
}

/// Timestamps for the console's lines, from the Timestamper plugin
/// (US-JX-07). Keyed by *absolute* line number — [firstLine] is the absolute
/// number of `values[0]` — so they stay aligned when old lines are dropped.
class ConsoleTimestamps {
  const ConsoleTimestamps({
    required this.firstLine,
    required this.values,
    this.pluginMissing = false,
    this.embedded = false,
  });

  static const none = ConsoleTimestamps(firstLine: 0, values: []);

  final int firstLine;
  final List<String> values;

  /// The server has no Timestamper plugin (404).
  final bool pluginMissing;

  /// The log itself carries timestamps (pipelines), so none were fetched.
  final bool embedded;

  /// True when this build recorded no timestamps at all (Timestamper
  /// returns an empty body, not a 404, for a job without `timestamps()`).
  bool get isEmpty => values.every((value) => value.trim().isEmpty);

  String? at(int absoluteLine) {
    final index = absoluteLine - firstLine;
    if (index < 0 || index >= values.length) return null;
    final value = values[index].trim();
    return value.isEmpty ? null : value;
  }
}

/// Fetches timestamps for exactly the lines on screen (a negative
/// `startLine` counts back from the end, verified on the fixture), only
/// while the preference is on. While the log streams, it re-fetches at most
/// every [_throttle] rather than on every 1 s chunk.
@riverpod
class ConsoleTimestampsNotifier extends _$ConsoleTimestampsNotifier {
  static const _throttle = Duration(seconds: 5);
  Timer? _timer;

  @override
  Future<ConsoleTimestamps> build(String buildUrl) async {
    ref.onDispose(() => _timer?.cancel());
    final enabled = ref.watch(
      consolePrefsNotifierProvider.select((prefs) => prefs.timestamps),
    );
    if (!enabled) return ConsoleTimestamps.none;

    final log = await ref.read(buildLogNotifierProvider(buildUrl).future);
    // Refresh (throttled) as the log grows.
    ref.listen(
      buildLogNotifierProvider(
        buildUrl,
      ).select((value) => value.value?.visibleLines.length),
      (_, _) => _timer ??= Timer(_throttle, () {
        _timer = null;
        ref.invalidateSelf();
      }),
    );

    final count = log.visibleLines.length;
    if (count == 0) return ConsoleTimestamps.none;
    // Pipelines carry Timestamper times in the log itself (see
    // `ConsoleLine.fromSpans`): nothing to fetch.
    if (log.visibleLines.any((line) => line.timestamp != null)) {
      return const ConsoleTimestamps(firstLine: 0, values: [], embedded: true);
    }
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .fetchTimestamps(buildUrl, startLine: -count);
    final values = result.fold((values) => values, (failure) => throw failure);
    if (values == null) {
      return const ConsoleTimestamps(
        firstLine: 0,
        values: [],
        pluginMissing: true,
      );
    }
    // The response is aligned to the *last* `values.length` lines.
    return ConsoleTimestamps(
      firstLine: log.droppedLines + count - values.length,
      values: values,
    );
  }
}

/// Search over the console's lines (US-JX-07): the query, its matches (line
/// indices into `visibleLines`), and which match is current.
class ConsoleSearch {
  const ConsoleSearch({
    this.query = '',
    this.matches = const [],
    this.current = 0,
  });

  final String query;
  final List<int> matches;
  final int current;

  int? get currentLine => matches.isEmpty ? null : matches[current];

  /// "3 / 17", or "0 / 0" with a query and no matches.
  String get counter =>
      matches.isEmpty ? '0 / 0' : '${current + 1} / ${matches.length}';
}

@riverpod
class ConsoleSearchNotifier extends _$ConsoleSearchNotifier {
  String _query = '';
  int _current = 0;

  @override
  ConsoleSearch build(String buildUrl) {
    final lines =
        ref.watch(buildLogNotifierProvider(buildUrl)).value?.visibleLines ??
        const <ConsoleLine>[];
    final matches = searchLines(lines, _query);
    if (_current >= matches.length) _current = 0;
    return ConsoleSearch(query: _query, matches: matches, current: _current);
  }

  void setQuery(String query) {
    _query = query;
    _current = 0;
    ref.invalidateSelf();
  }

  void next() => _step(1);

  void previous() => _step(-1);

  void _step(int delta) {
    final count = state.matches.length;
    if (count == 0) return;
    _current = (_current + delta) % count;
    if (_current < 0) _current += count;
    state = ConsoleSearch(
      query: _query,
      matches: state.matches,
      current: _current,
    );
  }
}

/// US-JX-07 "Save full log": streams `consoleText` into a temp `.log` file,
/// shares it, then deletes it. The log can hold secrets Jenkins didn't
/// mask, so nothing is kept once it's been shared. State is loading while
/// the download runs.
@riverpod
class FullLogExportNotifier extends _$FullLogExportNotifier {
  @override
  FutureOr<void> build(String buildUrl) {}

  Future<void> export({required String fileName}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final directory = await ref.read(tempDirectoryProvider.future);
    final file = File('${directory.path}/$fileName');
    try {
      final result = await ref
          .read(jenkinsRepositoryProvider)
          .downloadConsoleText(buildUrl, file.path);
      switch (result) {
        case Ok():
          await ref.read(fileSharerProvider)(file.path, fileName);
          if (ref.mounted) state = const AsyncData(null);
        case Err(:final error):
          if (!ref.mounted) return;
          state = AsyncError(error, StackTrace.current);
          ref
              .read(toastControllerProvider)
              .show(
                type: ToastType.error,
                title: "Couldn't save the log",
                message: error.message,
              );
      }
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }
}
