import 'jenkins_build.dart';

/// Builds per history page (US-JX-06), matching the original 20.
const historyPageSize = 20;

/// The result filter chips on job history (US-JX-06).
enum HistoryResultFilter {
  all('All'),
  failed('Failed'),
  unstable('Unstable'),
  success('Success'),
  aborted('Aborted'),
  running('Running');

  const HistoryResultFilter(this.label);

  final String label;

  bool matches(JenkinsBuild build) => switch (this) {
    all => true,
    running => build.building,
    failed => !build.building && build.result == 'FAILURE',
    unstable => !build.building && build.result == 'UNSTABLE',
    success => !build.building && build.result == 'SUCCESS',
    aborted => !build.building && build.result == 'ABORTED',
  };
}

class HistoryFilter {
  const HistoryFilter({
    this.result = HistoryResultFilter.all,
    this.startedByMe = false,
  });

  final HistoryResultFilter result;

  /// Only builds whose cause names [username] (US-JX-06).
  final bool startedByMe;

  bool get isActive => result != HistoryResultFilter.all || startedByMe;

  HistoryFilter copyWith({HistoryResultFilter? result, bool? startedByMe}) =>
      HistoryFilter(
        result: result ?? this.result,
        startedByMe: startedByMe ?? this.startedByMe,
      );
}

/// Applies [filter] to already-loaded [builds]. [username] is the active
/// server's Jenkins user; "started by me" matches its `UserIdCause`.
List<JenkinsBuild> filterHistory(
  List<JenkinsBuild> builds,
  HistoryFilter filter, {
  String? username,
}) => [
  for (final build in builds)
    if (filter.result.matches(build) &&
        (!filter.startedByMe ||
            (username != null && build.startedByUserIds.contains(username))))
      build,
];

/// The folder path of a job, from its URL, for search results (US-JX-06,
/// AUD-33): `…/job/team/job/api/job/main/` → `team / api`. Empty at the
/// root. Segments are URL-decoded, e.g. `feature%2Flogin` becomes
/// `feature/login`.
String folderPathOf(String jobUrl) {
  final segments = Uri.tryParse(jobUrl)?.pathSegments ?? const <String>[];
  final names = <String>[];
  for (var i = 0; i + 1 < segments.length; i++) {
    if (segments[i] == 'job' && segments[i + 1].isNotEmpty) {
      names.add(segments[i + 1]);
    }
  }
  if (names.length <= 1) return '';
  return names.sublist(0, names.length - 1).join(' / ');
}
