import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
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
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        byKey: {...state.byKey, ...value},
        pending: stillPending,
      ),
      Err(:final error) => state.copyWith(
        pending: stillPending,
        failure: error,
      ),
    };
  }
}
