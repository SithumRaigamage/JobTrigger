import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/cache/sonarqube_watch_store.dart';
import '../../../domain/sonarqube/sonarqube_analysis_status.dart';
import '../../../domain/sonarqube/sonarqube_project_watch.dart';
import '../../../domain/sonarqube/sonarqube_quality_gate.dart';
import '../../../domain/sonarqube/sonarqube_repository.dart';

/// A credential's repository for a gate check. Returns null when that
/// credential is gone (deleted, or the account was signed out), which drops
/// its watches; throws when it can't be *reached* right now, which keeps
/// them for the next check — the same contract as `RepositoryForServer`.
typedef GateRepositoryForCredential =
    Future<SonarQubeRepository?> Function(String credentialId);

/// Runs a store write in turn with the caller's other writes, so a check's
/// final load-and-save can't interleave with a watch being added or removed.
typedef SerializeGateWrite =
    Future<List<SonarQubeProjectWatch>> Function(
      Future<List<SonarQubeProjectWatch>> Function(),
    );

/// One pass over every gate watch (`US-SQ-WATCH-01`), shared by the in-app
/// timer and the background task so both behave identically. Returns the
/// watches that remain.
///
/// Reads the gate and the newest analysis's time per project, decides with
/// the pure [decideGateWatch], and — as `runWatchCheck` does (AUD-49) —
/// applies the outcomes to a fresh load of the store at the end, so a watch
/// added or removed during the pass survives that change.
Future<List<SonarQubeProjectWatch>> runSonarQubeWatchCheck({
  required SonarQubeWatchStore store,
  required GateRepositoryForCredential repositoryFor,
  required Future<void> Function(SonarQubeGateNotification) notify,
  SerializeGateWrite? serialize,
}) async {
  final watches = await store.load();
  if (watches.isEmpty) return const [];

  // Key -> what to store instead (null: drop). Unlisted: untouched.
  final outcomes = <String, SonarQubeProjectWatch?>{};
  final repositories = <String, SonarQubeRepository?>{};

  for (final watch in watches) {
    SonarQubeRepository? repository;
    try {
      repository = repositories.containsKey(watch.credentialId)
          ? repositories[watch.credentialId]
          : repositories[watch.credentialId] = await repositoryFor(
              watch.credentialId,
            );
    } on Object {
      continue; // Unreachable right now: leave it for later.
    }
    if (repository == null) {
      outcomes[watch.key] = null; // Credential gone: drop.
      continue;
    }

    final gate = await repository.fetchQualityGate(watch.projectKey);
    if (gate is! Ok<SonarQubeQualityGate, AppFailure>) continue;
    // Without the analysis time, analyses cannot be told apart, so a pass
    // that can't read it changes nothing.
    final status = await repository.fetchAnalysisStatus(watch.projectKey);
    if (status is! Ok<SonarQubeAnalysisStatus, AppFailure>) continue;

    final outcome = decideGateWatch(
      watch,
      gate: gate.value,
      analysisDate: _analysisTime(status.value),
    );
    if (outcome.notify case final notification?) await notify(notification);
    outcomes[watch.key] = outcome.keep;
  }

  Future<List<SonarQubeProjectWatch>> commit() async {
    final merged = [
      for (final current in await store.load())
        if (!outcomes.containsKey(current.key))
          current
        else
          ?outcomes[current.key],
    ];
    await store.save(merged);
    return merged;
  }

  return serialize == null ? commit() : serialize(commit);
}

/// The newest scan's completion time, or its submission time for a scan that
/// hasn't finished — the moment the gate on screen belongs to.
String? _analysisTime(SonarQubeAnalysisStatus status) =>
    status.current?.when?.toIso8601String();
