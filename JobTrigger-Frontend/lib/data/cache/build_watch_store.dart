import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/jenkins/build_watch.dart';

part 'build_watch_store.g.dart';

/// Persists build watches (US-JX-10) in `shared_preferences`: job URLs,
/// names, and numbers only — nothing secret. Shared by the app and the
/// background task, which runs in its own isolate.
class BuildWatchStore {
  static const _key = 'build_watches';

  Future<List<BuildWatch>> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Another isolate (the background task) may have written since.
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          BuildWatch.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const []; // Corrupt: start clean.
    }
  }

  Future<void> save(List<BuildWatch> watches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final watch in watches) watch.toJson()]),
    );
  }
}

@Riverpod(keepAlive: true)
BuildWatchStore buildWatchStore(Ref ref) => BuildWatchStore();
