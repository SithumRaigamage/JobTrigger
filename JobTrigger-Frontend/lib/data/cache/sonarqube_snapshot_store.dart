import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/sonarqube/sonarqube_overview_trend.dart';

part 'sonarqube_snapshot_store.g.dart';

/// Overview snapshots (`US-SQ-OVERVIEW-02`) in `shared_preferences`, one list
/// per credential: counts and times only, nothing secret.
class SonarQubeSnapshotStore {
  static const prefix = 'sonarqube_snapshots_';

  Future<List<SonarQubeOverviewSnapshot>> load(String credentialId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$prefix$credentialId');
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          SonarQubeOverviewSnapshot.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const []; // Corrupt: start clean.
    }
  }

  Future<void> save(
    String credentialId,
    List<SonarQubeOverviewSnapshot> snapshots,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$prefix$credentialId',
      jsonEncode([for (final s in snapshots) s.toJson()]),
    );
  }
}

@Riverpod(keepAlive: true)
SonarQubeSnapshotStore sonarQubeSnapshotStore(Ref ref) =>
    SonarQubeSnapshotStore();
