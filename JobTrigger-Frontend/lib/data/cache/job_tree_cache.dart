import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';

part 'job_tree_cache.g.dart';

/// A cached folder listing and when it was fetched (US-JX-20).
typedef CachedListing = ({List<JenkinsJob> jobs, DateTime savedAt});

/// US-JX-20: last-known folder listings per server, for browsing offline.
///
/// Lives in the platform *cache* directory. iOS `Library/Caches` and the
/// Android cache dir are excluded from iCloud and auto-backup, which is
/// the story's requirement, and the OS may purge them, which is fine for a
/// cache. Only non-secret fields are stored: names, URLs, colors, and
/// last-build numbers. Cleared on logout and when a server is deleted.
class JobTreeCache {
  JobTreeCache(this._directory);

  /// Resolves lazily, so nothing touches the filesystem until first use.
  final Future<Directory> Function() _directory;

  Future<Directory> _serverDir(String serverId) async {
    final base = await _directory();
    return Directory('${base.path}/job_tree/${_safe(serverId)}');
  }

  static String _safe(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');

  Future<File> _file(String serverId, String folderKey) async =>
      File('${(await _serverDir(serverId)).path}/${_safe(folderKey)}.json');

  Future<void> write(
    String serverId,
    String folderKey,
    List<JenkinsJob> jobs, {
    DateTime? now,
  }) async {
    final file = await _file(serverId, folderKey);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'savedAt': (now ?? DateTime.now()).toIso8601String(),
        'jobs': [for (final job in jobs) _jobToJson(job)],
      }),
    );
  }

  /// The cached listing, or null when there is none or it's unreadable.
  Future<CachedListing?> read(String serverId, String folderKey) async {
    try {
      final file = await _file(serverId, folderKey);
      if (!file.existsSync()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return (
        jobs: [
          for (final job in json['jobs'] as List<dynamic>)
            _jobFromJson(job as Map<String, dynamic>),
        ],
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
    } on Object {
      return null; // A corrupt cache is just no cache.
    }
  }

  Future<void> clearServer(String serverId) async {
    final dir = await _serverDir(serverId);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<void> clearAll() async {
    final dir = Directory('${(await _directory()).path}/job_tree');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  static Map<String, Object?> _jobToJson(JenkinsJob job) => {
    'name': job.name,
    'url': job.url,
    'class': job.jobClass,
    'displayName': job.displayName,
    'description': job.description,
    'color': job.color,
    'buildable': job.buildable,
    // A folder's children aren't cached with it: each folder is its own
    // entry. `[]` just keeps it recognisable as a folder.
    'isFolder': job.jobs != null,
    if (job.lastBuild case final build?)
      'lastBuild': {
        'number': build.number,
        'url': build.url,
        'result': build.result,
        'timestamp': build.timestamp,
        'building': build.building,
      },
  };

  static JenkinsJob _jobFromJson(Map<String, dynamic> json) {
    final build = json['lastBuild'] as Map<String, dynamic>?;
    return JenkinsJob(
      name: json['name'] as String,
      url: json['url'] as String,
      jobClass: json['class'] as String?,
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String?,
      buildable: json['buildable'] as bool?,
      jobs: json['isFolder'] == true ? const [] : null,
      lastBuild: build == null
          ? null
          : JenkinsBuild(
              number: (build['number'] as num).toInt(),
              url: build['url'] as String,
              result: build['result'] as String?,
              timestamp: (build['timestamp'] as num).toDouble(),
              building: build['building'] == true,
            ),
    );
  }
}

@Riverpod(keepAlive: true)
JobTreeCache jobTreeCache(Ref ref) =>
    JobTreeCache(getApplicationCacheDirectory);
