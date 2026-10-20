import '../jenkins/jenkins_job.dart';
import '../jenkins/jenkins_link.dart';

/// A pinned job's status as the home-screen widget shows it (US-JX-23).
enum WidgetJobStatus { success, failure, unstable, running, other }

/// One widget row. Names, links, and build numbers only: never credentials.
class WidgetJob {
  const WidgetJob({
    required this.label,
    required this.link,
    required this.status,
    required this.statusText,
    this.buildNumber,
    this.buildTimestamp,
  });

  final String label;

  /// `jobtrigger://app/open?url=…` (US-JX-19), so a tap opens the job.
  final String link;
  final WidgetJobStatus status;

  /// Spelled out, so status never relies on color alone (NFR-A11Y-03).
  final String statusText;
  final int? buildNumber;

  /// Epoch milliseconds of the last build's start.
  final int? buildTimestamp;

  Map<String, Object?> toJson() => {
    'label': label,
    'link': link,
    'status': status.name,
    'statusText': statusText,
    'buildNumber': buildNumber,
    'buildTimestamp': buildTimestamp,
  };
}

/// What the app hands the widget. The widget renders it and never fetches
/// anything itself.
class WidgetSnapshot {
  const WidgetSnapshot({required this.jobs, required this.updatedAt});

  /// A medium widget shows four rows; a small one the first two.
  static const maxJobs = 4;

  final List<WidgetJob> jobs;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'jobs': [for (final job in jobs) job.toJson()],
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };
}

/// A pin plus its last known status, or null while unknown (still loading,
/// failed, or the job is gone).
typedef PinnedStatus = ({String label, String url, JenkinsJob? job});

WidgetSnapshot buildWidgetSnapshot(
  List<PinnedStatus> pins, {
  required DateTime now,
}) => WidgetSnapshot(
  jobs: [
    for (final pin in pins.take(WidgetSnapshot.maxJobs))
      _widgetJob(pin.label, pin.url, pin.job),
  ],
  updatedAt: now,
);

WidgetJob _widgetJob(String label, String url, JenkinsJob? job) {
  final color = job?.color?.toLowerCase();
  final building = color?.endsWith('_anime') ?? false;
  final (status, text) = switch (color?.replaceAll('_anime', '')) {
    _ when building => (WidgetJobStatus.running, 'Building'),
    'blue' => (WidgetJobStatus.success, 'Success'),
    'red' => (WidgetJobStatus.failure, 'Failed'),
    'yellow' => (WidgetJobStatus.unstable, 'Unstable'),
    'aborted' => (WidgetJobStatus.other, 'Aborted'),
    'disabled' => (WidgetJobStatus.other, 'Disabled'),
    'notbuilt' => (WidgetJobStatus.other, 'Not built'),
    _ => (WidgetJobStatus.other, 'Unknown'),
  };
  return WidgetJob(
    label: label,
    link: jobTriggerLinkFor(url).toString(),
    status: status,
    statusText: text,
    buildNumber: job?.lastBuild?.number,
    buildTimestamp: job?.lastBuild?.timestamp.toInt(),
  );
}
