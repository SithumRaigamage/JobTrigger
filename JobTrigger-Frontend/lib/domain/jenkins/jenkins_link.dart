import '../credential/jenkins_server.dart';

/// Where a Jenkins URL points, resolved against a saved server (US-JX-19).
class JenkinsLinkTarget {
  const JenkinsLinkTarget({
    required this.server,
    required this.jobUrl,
    required this.jobLabel,
    this.buildNumber,
    this.showLog = false,
  });

  final JenkinsServer server;

  /// The job's URL on [server]'s own base URL, whatever host the link used.
  final String jobUrl;

  /// The job's (decoded) name, for titles until its detail loads.
  final String jobLabel;

  /// A specific build, if the link named one.
  final int? buildNumber;

  /// The link was to a console (`…/console`, `…/consoleText`,
  /// `…/consoleFull`).
  final bool showLog;

  String? get buildUrl => buildNumber == null ? null : '$jobUrl$buildNumber/';
}

/// Why a link couldn't be opened.
enum JenkinsLinkProblem {
  /// Not a web URL at all.
  invalid,

  /// It carries `user:password@`: never followed (US-JX-19 security note).
  credentialsInUrl,

  /// No saved server has this host and context path.
  unknownServer,

  /// On a saved server, but not a job URL.
  notAJob,
}

/// Resolves [link] against [servers] (US-JX-19): the server whose host,
/// port, and context path match (the longest context path wins), and the
/// job, build, and console it names. `/view/…` segments are skipped, since
/// a job's URL is the same in any view. Returns either a
/// [JenkinsLinkTarget] or a [JenkinsLinkProblem].
Object resolveJenkinsLink(String link, List<JenkinsServer> servers) {
  final uri = Uri.tryParse(link.trim());
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    return JenkinsLinkProblem.invalid;
  }
  if (uri.userInfo.isNotEmpty) return JenkinsLinkProblem.credentialsInUrl;

  JenkinsServer? match;
  var matchedPrefix = <String>[];
  for (final server in servers) {
    final base = Uri.tryParse(server.jenkinsURL);
    if (base == null || base.host.toLowerCase() != uri.host.toLowerCase()) {
      continue;
    }
    if (base.port != uri.port) continue;
    final prefix = base.pathSegments.where((s) => s.isNotEmpty).toList();
    final path = uri.pathSegments;
    final startsWith =
        path.length >= prefix.length &&
        List.generate(
          prefix.length,
          (i) => path[i] == prefix[i],
        ).every((ok) => ok);
    if (startsWith && (match == null || prefix.length > matchedPrefix.length)) {
      match = server;
      matchedPrefix = prefix;
    }
  }
  if (match == null) return JenkinsLinkProblem.unknownServer;

  final rest = uri.pathSegments
      .skip(matchedPrefix.length)
      .where((s) => s.isNotEmpty)
      .toList();
  final jobNames = <String>[];
  int? buildNumber;
  var showLog = false;
  var i = 0;
  while (i < rest.length) {
    final segment = rest[i];
    if (segment == 'view' && i + 1 < rest.length && jobNames.isEmpty) {
      i += 2; // A view prefix: same job either way.
    } else if (segment == 'job' && i + 1 < rest.length) {
      jobNames.add(rest[i + 1]);
      i += 2;
    } else if (jobNames.isNotEmpty && int.tryParse(segment) != null) {
      buildNumber = int.parse(segment);
      final next = i + 1 < rest.length ? rest[i + 1] : null;
      showLog = next != null && next.startsWith('console');
      break;
    } else {
      break; // e.g. `lastBuild`, `configure`: the job itself.
    }
  }
  if (jobNames.isEmpty) return JenkinsLinkProblem.notAJob;

  final base = match.jenkinsURL.endsWith('/')
      ? match.jenkinsURL
      : '${match.jenkinsURL}/';
  return JenkinsLinkTarget(
    server: match,
    jobUrl: '${base}job/${jobNames.map(Uri.encodeComponent).join('/job/')}/',
    jobLabel: jobNames.last,
    buildNumber: buildNumber,
    showLog: showLog,
  );
}

/// The in-app deep link for [jenkinsUrl]: `jobtrigger://app/open?url=…`.
Uri jobTriggerLinkFor(String jenkinsUrl) => Uri(
  scheme: 'jobtrigger',
  host: 'app',
  path: '/open',
  queryParameters: {'url': jenkinsUrl},
);
