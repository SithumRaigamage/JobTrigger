import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/cache/sonarqube_cache.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_project_summary.dart';

part 'sonarqube_summaries_notifier.g.dart';

/// The headline numbers loaded so far, for the project cards and the
/// overview (`US-SQ-PROJ-03`).
class SonarQubeSummaries {
  const SonarQubeSummaries({
    this.byKey = const {},
    this.pending = const {},
    this.failure,
  });

  final Map<String, SonarQubeProjectSummary> byKey;

  /// Project keys being fetched right now.
  final Set<String> pending;

  /// Set when the last fetch failed; the cards and overview then work
  /// without the numbers rather than failing.
  final Object? failure;

  bool get isLoading => pending.isNotEmpty;

  SonarQubeSummaries copyWith({
    Map<String, SonarQubeProjectSummary>? byKey,
    Set<String>? pending,
    Object? failure,
    bool clearFailure = false,
  }) => SonarQubeSummaries(
    byKey: byKey ?? this.byKey,
    pending: pending ?? this.pending,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

/// Fetches summaries for whatever projects are on screen, once each, in
/// batches. A failure leaves the projects as they were and can be retried.
/// Rebuilds, and so forgets everything, when the credential changes.
@riverpod
class SonarQubeSummariesNotifier extends _$SonarQubeSummariesNotifier {
  @override
  SonarQubeSummaries build() {
    ref.watch(sonarQubeRepositoryProvider);
    return const SonarQubeSummaries();
  }

  /// Loads the summaries of [keys] that are neither loaded nor being loaded.
  Future<void> ensure(List<String> keys) async {
    final missing = [
      for (final key in keys)
        if (!state.byKey.containsKey(key) && !state.pending.contains(key)) key,
    ];
    if (missing.isEmpty) return;
    state = state.copyWith(
      pending: {...state.pending, ...missing},
      clearFailure: true,
    );
    final result = await ref
        .read(sonarQubeRepositoryProvider)
        .fetchProjectSummaries(missing);
    if (!ref.mounted) return;
    final stillPending = {...state.pending}..removeAll(missing);
    final credentialId = ref
        .read(activeSonarQubeCredentialNotifierProvider)
        ?.id;
    final cache = ref.read(sonarQubeCacheProvider);
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          byKey: {...state.byKey, ...value},
          pending: stillPending,
        );
        if (credentialId != null) {
          unawaited(
            cache.mergeSummaries(credentialId, value).catchError((Object _) {}),
          );
        }
      case Err(:final error):
        // The failure is shown at once; with no connection, saved numbers
        // then take its place (US-SQ-OFFLINE-01: the list says it is a saved
        // copy). Any other failure stays as it is.
        state = state.copyWith(pending: stillPending, failure: error);
        if (error is! NetworkFailure || credentialId == null) return;
        final saved = await cache
            .read(credentialId)
            .catchError((Object _) => null);
        if (!ref.mounted) return;
        final fromCopy = {
          for (final key in missing)
            if (saved?.summaries[key] != null) key: saved!.summaries[key]!,
        };
        if (fromCopy.isNotEmpty) {
          state = state.copyWith(
            byKey: {...state.byKey, ...fromCopy},
            clearFailure: true,
          );
        }
    }
  }
}
