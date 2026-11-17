import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/sonarqube/sonarqube_project_watch.dart';

part 'sonarqube_watch_store.g.dart';

/// Persists gate watches (`US-SQ-WATCH-01`) in `shared_preferences`: a
/// credential id, a project key and name, and the analysis already judged —
/// nothing secret. Shared by the app and the background task, which runs in
/// its own isolate.
class SonarQubeWatchStore {
  static const _key = 'sonarqube_watches';

  Future<List<SonarQubeProjectWatch>> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Another isolate (the background task) may have written since.
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          SonarQubeProjectWatch.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const []; // Corrupt: start clean.
    }
  }

  Future<void> save(List<SonarQubeProjectWatch> watches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final watch in watches) watch.toJson()]),
    );
  }
}

@Riverpod(keepAlive: true)
SonarQubeWatchStore sonarQubeWatchStore(Ref ref) => SonarQubeWatchStore();
