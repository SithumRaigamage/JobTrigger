import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/cache/sonarqube_snapshot_store.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/sonarqube/sonarqube_overview.dart';
import '../../../domain/sonarqube/sonarqube_overview_trend.dart';

part 'sonarqube_overview_trend_notifier.g.dart';

/// What the Overview shows about direction (`US-SQ-OVERVIEW-02`).
class SonarQubeTrendState {
  const SonarQubeTrendState({this.trend, this.recorded = false});

  /// Null until a snapshot at least an hour old exists.
  final SonarQubeOverviewTrend? trend;

  /// True once this visit has been compared and saved, so the screen can
  /// tell "starts now" from "not loaded yet".
  final bool recorded;
}

/// Compares the loaded Overview with the snapshots this device kept, and
/// saves this visit as the next one. Only a fully loaded Overview counts: a
/// half-loaded one would look like a sudden improvement.
@riverpod
class SonarQubeOverviewTrendNotifier extends _$SonarQubeOverviewTrendNotifier {
  String? _recordedFor;

  @override
  SonarQubeTrendState build() {
    ref.watch(activeSonarQubeCredentialNotifierProvider);
    _recordedFor = null;
    return const SonarQubeTrendState();
  }

  Future<void> record(SonarQubeOverview overview, {DateTime? now}) async {
    final credential = ref.read(activeSonarQubeCredentialNotifierProvider);
    if (credential == null || overview.unknown > 0) return;
    final signature =
        '${overview.failing}/${overview.warning}/${overview.passing}';
    if (_recordedFor == signature) return;
    _recordedFor = signature;

    final store = ref.read(sonarQubeSnapshotStoreProvider);
    try {
      final history = await store.load(credential.id);
      final outcome = compareWithSnapshots(
        history,
        overview,
        now ?? DateTime.now(),
      );
      await store.save(credential.id, outcome.history);
      if (!ref.mounted) return;
      state = SonarQubeTrendState(trend: outcome.trend, recorded: true);
    } on Object {
      // A trend is a nicety: storage that is unavailable shows no trend line
      // rather than an error on the Overview.
    }
  }
}
