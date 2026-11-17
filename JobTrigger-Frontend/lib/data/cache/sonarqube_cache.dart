import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/sonarqube/sonarqube_project.dart';
import '../../domain/sonarqube/sonarqube_project_summary.dart';
import '../../domain/sonarqube/sonarqube_quality_gate.dart';

part 'sonarqube_cache.g.dart';

/// The last project list and gate numbers the app loaded for a credential,
/// with when they were saved (`US-SQ-OFFLINE-01`).
typedef SonarQubeSavedCopy = ({
  List<SonarQubeProject> projects,
  int total,
  Map<String, SonarQubeProjectSummary> summaries,
  DateTime savedAt,
});

/// `US-SQ-OFFLINE-01`: the last-known project list and card numbers per
/// credential, for looking at a project with no connection.
///
/// Same place and same rules as the Jenkins tree cache ([JobTreeCache],
/// `US-JX-20`): the platform *cache* directory, which iOS excludes from
/// iCloud and Android from auto-backup, and which the OS may purge — fine for
/// a cache. Only project keys, names, dates, the gate verdict and four
/// numbers are written: never the token, the server address or an issue.
/// Cleared at logout and when a credential is deleted.
class SonarQubeCache {
  SonarQubeCache(this._directory);

  /// Resolves lazily, so nothing touches the filesystem until first use.
  final Future<Directory> Function() _directory;

  /// Writes run one after another: the list and the numbers are saved
  /// without being awaited by their callers, and the numbers are merged into
  /// the file the list creates.
  Future<void> _last = Future<void>.value();

  Future<void> _serial(Future<void> Function() job) {
    final run = _last.then((_) => job());
    _last = run.catchError((Object _) {});
    return run;
  }

  Future<Directory> _dir() async =>
      Directory('${(await _directory()).path}/sonarqube');

  static String _safe(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');

  Future<File> _file(String credentialId) async =>
      File('${(await _dir()).path}/${_safe(credentialId)}.json');

  Future<Map<String, dynamic>> _read(String credentialId) async {
    try {
      final file = await _file(credentialId);
      if (!file.existsSync()) return {};
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on Object {
      return {}; // A corrupt cache is just no cache.
    }
  }

  Future<void> _write(String credentialId, Map<String, dynamic> json) async {
    final file = await _file(credentialId);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(json));
  }

  /// Saves the first page of projects, replacing the saved list. The saved
  /// numbers are kept for the projects still in it.
  Future<void> writeProjects(
    String credentialId,
    List<SonarQubeProject> projects,
    int total, {
    DateTime? now,
  }) => _serial(() async {
    final json = await _read(credentialId);
    final keys = {for (final p in projects) p.key};
    final summaries = (json['summaries'] as Map<String, dynamic>? ?? {})
      ..removeWhere((key, _) => !keys.contains(key));
    await _write(credentialId, {
      'savedAt': (now ?? DateTime.now()).toIso8601String(),
      'total': total,
      'projects': [
        for (final p in projects)
          {
            'key': p.key,
            'name': p.name,
            'analysed': p.lastAnalysisDate?.toIso8601String(),
          },
      ],
      'summaries': summaries,
    });
  });

  /// Adds [summaries] to the saved numbers. Does nothing before a project
  /// list has been saved: the numbers are only shown beside it.
  Future<void> mergeSummaries(
    String credentialId,
    Map<String, SonarQubeProjectSummary> summaries,
  ) => _serial(() async {
    final json = await _read(credentialId);
    if (json['projects'] == null) return;
    final saved = (json['summaries'] as Map<String, dynamic>? ?? {});
    for (final entry in summaries.entries) {
      saved[entry.key] = {
        'gate': entry.value.gate.name,
        'bugs': entry.value.bugs,
        'vulnerabilities': entry.value.vulnerabilities,
        'codeSmells': entry.value.codeSmells,
        'coverage': entry.value.coverage,
      };
    }
    json['summaries'] = saved;
    await _write(credentialId, json);
  });

  /// The saved copy, or null when there is none or it is unreadable.
  Future<SonarQubeSavedCopy?> read(String credentialId) async {
    await _last; // Anything being saved lands first.
    final json = await _read(credentialId);
    try {
      final projects = json['projects'] as List<dynamic>?;
      if (projects == null) return null;
      final summaries = json['summaries'] as Map<String, dynamic>? ?? {};
      return (
        projects: [
          for (final p in projects.cast<Map<String, dynamic>>())
            SonarQubeProject(
              key: p['key'] as String,
              name: p['name'] as String,
              lastAnalysisDate: p['analysed'] == null
                  ? null
                  : DateTime.tryParse(p['analysed'] as String),
            ),
        ],
        total: json['total'] as int? ?? projects.length,
        summaries: {
          for (final entry in summaries.entries)
            entry.key: _summary(entry.value as Map<String, dynamic>),
        },
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
    } on Object {
      return null;
    }
  }

  static SonarQubeProjectSummary _summary(Map<String, dynamic> json) =>
      SonarQubeProjectSummary(
        gate: QualityGateState.values.firstWhere(
          (state) => state.name == json['gate'],
          orElse: () => QualityGateState.none,
        ),
        bugs: json['bugs'] as int?,
        vulnerabilities: json['vulnerabilities'] as int?,
        codeSmells: json['codeSmells'] as int?,
        coverage: (json['coverage'] as num?)?.toDouble(),
      );

  Future<void> clearCredential(String credentialId) => _serial(() async {
    final file = await _file(credentialId);
    if (file.existsSync()) await file.delete();
  });

  Future<void> clearAll() => _serial(() async {
    final dir = await _dir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });
}

@Riverpod(keepAlive: true)
SonarQubeCache sonarQubeCache(Ref ref) =>
    SonarQubeCache(getApplicationCacheDirectory);
