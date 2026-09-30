import 'jenkins_build.dart';
import 'relative_time.dart';

/// Something the user asked to be told about (US-JX-10): one build
/// finishing, or every new build of a job finishing.
class BuildWatch {
  const BuildWatch({
    required this.serverId,
    required this.jobUrl,
    required this.jobLabel,
    this.buildNumber,
    this.lastNotified = 0,
  });

  factory BuildWatch.fromJson(Map<String, dynamic> json) => BuildWatch(
    serverId: json['serverId'] as String,
    jobUrl: json['jobUrl'] as String,
    jobLabel: json['jobLabel'] as String,
    buildNumber: (json['buildNumber'] as num?)?.toInt(),
    lastNotified: (json['lastNotified'] as num?)?.toInt() ?? 0,
  );

  final String serverId;
  final String jobUrl;
  final String jobLabel;

  /// Set for a one-build watch; null watches every new build of the job.
  final int? buildNumber;

  /// For a job watch: the newest build already notified (or current when
  /// the watch began), so only newer builds notify.
  final int lastNotified;

  bool get isJobWatch => buildNumber == null;

  /// Identity: one watch per build, one per job.
  String get key => '$serverId|$jobUrl|${buildNumber ?? 'job'}';

  BuildWatch withLastNotified(int number) => BuildWatch(
    serverId: serverId,
    jobUrl: jobUrl,
    jobLabel: jobLabel,
    buildNumber: buildNumber,
    lastNotified: number,
  );

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'jobUrl': jobUrl,
    'jobLabel': jobLabel,
    'buildNumber': buildNumber,
    'lastNotified': lastNotified,
  };
}

/// A notification to show. Only the job name, build number, result, and
/// duration go in it — never log text or anything secret (US-JX-10).
class BuildNotification {
  const BuildNotification({
    required this.title,
    required this.body,
    required this.jobUrl,
    required this.id,
  });

  final String title;
  final String body;

  /// Where a tap should go.
  final String jobUrl;

  /// Stable per build, so the same build never notifies twice.
  final int id;
}

/// What happens to one watch after a check: kept (possibly updated) or
/// dropped, and maybe a notification.
typedef WatchOutcome = ({BuildWatch? keep, BuildNotification? notify});

/// Decides [watch]'s outcome from the job's [recent] builds (newest first).
/// Pure, so the foreground and background checks share it exactly.
WatchOutcome decideWatch(BuildWatch watch, List<JenkinsBuild> recent) {
  bool finished(JenkinsBuild build) => !build.building && build.result != null;

  final number = watch.buildNumber;
  if (number != null) {
    final build = recent.where((b) => b.number == number).firstOrNull;
    if (build == null) {
      // Older than everything returned: it can't be observed any more.
      final oldest = recent.isEmpty ? null : recent.last.number;
      final gone = oldest != null && number < oldest;
      return (keep: gone ? null : watch, notify: null);
    }
    if (!finished(build)) return (keep: watch, notify: null);
    return (keep: null, notify: notificationFor(watch, build));
  }

  final newest = recent.where(finished).firstOrNull;
  if (newest == null || newest.number <= watch.lastNotified) {
    return (keep: watch, notify: null);
  }
  // Only the newest finished build, so a busy job doesn't spam.
  return (
    keep: watch.withLastNotified(newest.number),
    notify: notificationFor(watch, newest),
  );
}

BuildNotification notificationFor(BuildWatch watch, JenkinsBuild build) {
  final (mark, verb) = switch (build.result) {
    'SUCCESS' => ('✅', 'succeeded'),
    'FAILURE' => ('❌', 'failed'),
    'UNSTABLE' => ('⚠️', 'is unstable'),
    'ABORTED' => ('⏹', 'was aborted'),
    _ => ('•', 'finished'),
  };
  final duration = build.duration;
  return BuildNotification(
    title: '$mark ${watch.jobLabel} #${build.number} $verb',
    body: duration == null
        ? 'Tap to open'
        : 'Took ${formatBuildDuration(duration)}',
    jobUrl: watch.jobUrl,
    id: '${watch.jobUrl}#${build.number}'.hashCode & 0x7fffffff,
  );
}
