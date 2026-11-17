import 'jenkins_build.dart';
import 'jenkins_link.dart';
import 'relative_time.dart';

/// PI-07 / IMP-11: which finished builds a watch tells you about. Existing
/// stored watches default to [all], so upgrading never changes behaviour.
enum WatchRule {
  all,
  failuresOnly,
  backToGreenOnly,
  mainBranchOnly;

  String get label => switch (this) {
    WatchRule.all => 'All builds',
    WatchRule.failuresOnly => 'Failures only',
    WatchRule.backToGreenOnly => 'Back to green',
    WatchRule.mainBranchOnly => 'Main branch only',
  };

  String get description => switch (this) {
    WatchRule.all => 'Notify for every finished build.',
    WatchRule.failuresOnly => 'Only notify when a build fails.',
    WatchRule.backToGreenOnly =>
      'Only notify when a failure is followed by a success.',
    WatchRule.mainBranchOnly =>
      'Only notify for main, master or trunk builds. Best effort: the '
          'branch is inferred from a multibranch job URL, and a build whose '
          'branch cannot be read always notifies.',
  };

  /// A stored name, falling back to [all] for anything unknown so an older
  /// or corrupt entry keeps its long-standing behaviour.
  static WatchRule fromJson(Object? value) => switch (value) {
    final String name => WatchRule.values.firstWhere(
      (rule) => rule.name == name,
      orElse: () => WatchRule.all,
    ),
    _ => WatchRule.all,
  };
}

/// Something the user asked to be told about (US-JX-10): one build
/// finishing, or every new build of a job finishing.
class BuildWatch {
  const BuildWatch({
    required this.serverId,
    required this.jobUrl,
    required this.jobLabel,
    this.buildNumber,
    this.lastNotified = 0,
    this.rule = WatchRule.all,
  });

  factory BuildWatch.fromJson(Map<String, dynamic> json) => BuildWatch(
    serverId: json['serverId'] as String,
    jobUrl: json['jobUrl'] as String,
    jobLabel: json['jobLabel'] as String,
    buildNumber: (json['buildNumber'] as num?)?.toInt(),
    lastNotified: (json['lastNotified'] as num?)?.toInt() ?? 0,
    rule: WatchRule.fromJson(json['rule']),
  );

  final String serverId;
  final String jobUrl;
  final String jobLabel;

  /// Set for a one-build watch; null watches every new build of the job.
  final int? buildNumber;

  /// For a job watch: the newest build already notified (or current when
  /// the watch began), so only newer builds notify.
  final int lastNotified;

  /// PI-07: filters which finished builds notify. Defaults to [WatchRule.all].
  final WatchRule rule;

  bool get isJobWatch => buildNumber == null;

  /// Identity: one watch per build, one per job.
  String get key => '$serverId|$jobUrl|${buildNumber ?? 'job'}';

  BuildWatch withLastNotified(int number) => BuildWatch(
    serverId: serverId,
    jobUrl: jobUrl,
    jobLabel: jobLabel,
    buildNumber: buildNumber,
    lastNotified: number,
    rule: rule,
  );

  BuildWatch withRule(WatchRule rule) => BuildWatch(
    serverId: serverId,
    jobUrl: jobUrl,
    jobLabel: jobLabel,
    buildNumber: buildNumber,
    lastNotified: lastNotified,
    rule: rule,
  );

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'jobUrl': jobUrl,
    'jobLabel': jobLabel,
    'buildNumber': buildNumber,
    'lastNotified': lastNotified,
    'rule': rule.name,
  };
}

/// A notification to show. Only the job name, build number, result, and
/// duration go in it — never log text or anything secret (US-JX-10).
class BuildNotification {
  const BuildNotification({
    required this.title,
    required this.body,
    required this.jobUrl,
    required this.serverId,
    required this.id,
  });

  final String title;
  final String body;

  /// Where a tap should go.
  final String jobUrl;

  /// The saved server [jobUrl] belongs to, which may not be the active one
  /// when the tap arrives (AUD-45).
  final String serverId;

  /// AUD-54: the same notification without the job, its number, or its
  /// result, for while the app lock is on (a lock screen or a shared
  /// glance shouldn't name what's being built).
  BuildNotification redacted() => BuildNotification(
    title: 'A watched build finished',
    body: 'Unlock JobTrigger to see the result.',
    jobUrl: jobUrl,
    serverId: serverId,
    id: id,
  );

  /// What a tap opens: the in-app link, so it goes through the same
  /// server matching and switch confirmation as any other Jenkins link.
  String get payload =>
      jobTriggerLinkFor(jobUrl, serverId: serverId).toString();

  /// Stable per build, so the same build never notifies twice.
  final int id;
}

/// What happens to one watch after a check: kept (possibly updated) or
/// dropped, and maybe a notification.
typedef WatchOutcome = ({BuildWatch? keep, BuildNotification? notify});

/// Decides [watch]'s outcome from the job's [recent] builds (newest first).
/// Pure, so the foreground and background checks share it exactly. PI-07:
/// the watch's [WatchRule] filters which finished builds notify.
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
    // The one build this watch was for: consume it even when the rule does
    // not match, so a silent success cannot linger forever.
    return (
      keep: null,
      notify: _matchesRule(watch.rule, watch, build, recent)
          ? notificationFor(watch, build)
          : null,
    );
  }

  final newest = recent.where(finished).firstOrNull;
  if (newest == null || newest.number <= watch.lastNotified) {
    return (keep: watch, notify: null);
  }
  // Advance past the newest finished build whatever the rule says, so a
  // quiet success does not keep hiding the next failure.
  return (
    keep: watch.withLastNotified(newest.number),
    notify: _matchesRule(watch.rule, watch, newest, recent)
        ? notificationFor(watch, newest)
        : null,
  );
}

/// Whether [build] should notify under [rule]. A rule that cannot be
/// evaluated (the main-branch rule when no branch can be read) never
/// suppresses, so an unknown branch can't hide a real result.
bool _matchesRule(
  WatchRule rule,
  BuildWatch watch,
  JenkinsBuild build,
  List<JenkinsBuild> recent,
) => switch (rule) {
  WatchRule.all => true,
  WatchRule.failuresOnly => build.result == 'FAILURE',
  WatchRule.backToGreenOnly =>
    build.result == 'SUCCESS' && !_previousBuildSucceeded(build, recent),
  WatchRule.mainBranchOnly => _isMainBranch(watch, build),
};

/// True when the newest finished build older than [build] succeeded, i.e.
/// this build is not a "back to green" transition.
bool _previousBuildSucceeded(JenkinsBuild build, List<JenkinsBuild> recent) {
  final index = recent.indexWhere((b) => b.number == build.number);
  if (index < 0) return false;
  for (var i = index + 1; i < recent.length; i++) {
    final older = recent[i];
    if (older.building || older.result == null) continue;
    return older.result == 'SUCCESS';
  }
  return false;
}

const _mainBranchNames = {'main', 'master', 'trunk'};

bool _isMainBranch(BuildWatch watch, JenkinsBuild build) {
  final branch =
      _branchFromJobUrl(watch.jobUrl) ??
      _branchFromDisplayName(build.displayName);
  // Unknown: never suppress a notification we can't reason about.
  if (branch == null) return true;
  return _mainBranchNames.contains(branch.toLowerCase());
}

/// The branch segment of a multibranch job URL
/// (`.../job/<repo>/job/<branch>/`), URL-decoded. Null when the URL has
/// only one job segment, where there is no branch to read.
String? _branchFromJobUrl(String jobUrl) {
  final segments = jobUrl.split('/job/');
  // ['https://ci', 'repo', 'main/'] — at least two job segments.
  if (segments.length < 3) return null;
  final last = segments.last.replaceAll(RegExp(r'/+$'), '');
  if (last.isEmpty) return null;
  try {
    return Uri.decodeComponent(last);
  } on ArgumentError {
    return last;
  }
}

/// Some multibranch builds carry the branch in `displayName`, e.g.
/// `#12 (main)`. Use it only when it is explicit in parentheses.
String? _branchFromDisplayName(String? displayName) {
  if (displayName == null) return null;
  final match = RegExp(r'\(([^)]+)\)\s*$').firstMatch(displayName);
  return match?.group(1)?.trim();
}

BuildNotification notificationFor(BuildWatch watch, JenkinsBuild build) {
  // Worded, not marked with an emoji: the verb carries the result
  // (`UI-UX/screens/24-home-widget-notification`).
  final verb = switch (build.result) {
    'SUCCESS' => 'succeeded',
    'FAILURE' => 'failed',
    'UNSTABLE' => 'is unstable',
    'ABORTED' => 'was aborted',
    _ => 'finished',
  };
  final duration = build.duration;
  return BuildNotification(
    title: '${watch.jobLabel} #${build.number} $verb',
    body: duration == null
        ? 'Tap to open'
        : 'Finished in ${formatBuildDuration(duration)}',
    jobUrl: watch.jobUrl,
    serverId: watch.serverId,
    id: '${watch.jobUrl}#${build.number}'.hashCode & 0x7fffffff,
  );
}
