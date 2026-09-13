import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';

part 'build_log_notifier.g.dart';

/// Accumulates a build's console log via Jenkins' Progressive Text API,
/// family-keyed by the build's absolute URL. Polls ~1s between reads
/// (`docs/api-reference.md#polling-intervals`) — deliberately faster than
/// the old Swift app's fixed 3s (`BuildLogViewModel.setupTimer`); the docs
/// explicitly call for ~1s for this rewrite. Stops on its own once
/// `X-More-Data` is false. Timer always cancelled in `ref.onDispose`, same
/// leak discipline as `BuildStatusPollingNotifier` (P5-06).
@riverpod
class BuildLogNotifier extends _$BuildLogNotifier {
  Timer? _timer;
  int _offset = 0;

  @override
  Future<String> build(String buildUrl) async {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    final result = await ref
        .read(jenkinsRepositoryProvider)
        .streamBuildLog(buildUrl, start: _offset);
    return result.fold((chunk) {
      _offset = chunk.nextOffset;
      if (chunk.hasMoreData) _scheduleNext(buildUrl);
      return chunk.text;
    }, (failure) => throw failure);
  }

  void _scheduleNext(String buildUrl) {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () async {
      final result = await ref
          .read(jenkinsRepositoryProvider)
          .streamBuildLog(buildUrl, start: _offset);
      switch (result) {
        case Ok(:final value):
          _offset = value.nextOffset;
          state = AsyncData((state.value ?? '') + value.text);
          if (value.hasMoreData) _scheduleNext(buildUrl);
        case Err(:final error):
          state = AsyncError(error, StackTrace.current);
      }
    });
  }
}
