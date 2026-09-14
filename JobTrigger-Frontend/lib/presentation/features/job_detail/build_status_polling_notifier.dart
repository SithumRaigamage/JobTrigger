import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'job_detail_notifier.dart';
import 'pipeline_stages_notifier.dart';

part 'build_status_polling_notifier.g.dart';

/// Side-effect-only notifier: while the job's `lastBuild.building == true`,
/// invalidates `JobDetailNotifier` every 5s
/// (`docs/api-reference.md#polling-intervals`), stopping automatically once
/// the build finishes. Timer is always cancelled in `ref.onDispose` — the
/// #1 leak risk per the original migration notes, per this task's own
/// warning.
///
/// Also invalidates `PipelineStagesNotifier` (US-PIPE-04) for the current
/// build on the same tick, when a build URL is known — that story asks
/// for the stage list to live-update on this exact cadence, and doing it
/// here (rather than a second independent timer) is one less place a leak
/// could hide.
///
/// `JobDetailScreen` keeps this alive by watching it; it has no state of
/// its own worth reading.
@riverpod
class BuildStatusPollingNotifier extends _$BuildStatusPollingNotifier {
  Timer? _timer;

  @override
  void build(String jobUrl) {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    ref.listen(jobDetailNotifierProvider(jobUrl), (previous, next) {
      _reschedule(
        jobUrl,
        buildUrl: next.value?.lastBuild?.url,
        isBuilding: next.value?.lastBuild?.building ?? false,
      );
    }, fireImmediately: true);
  }

  void _reschedule(
    String jobUrl, {
    String? buildUrl,
    required bool isBuilding,
  }) {
    _timer?.cancel();
    _timer = null;
    if (!isBuilding) return;

    _timer = Timer(const Duration(seconds: 5), () {
      ref.invalidate(jobDetailNotifierProvider(jobUrl));
      if (buildUrl != null) {
        ref.invalidate(pipelineStagesNotifierProvider(buildUrl));
      }
    });
  }
}
