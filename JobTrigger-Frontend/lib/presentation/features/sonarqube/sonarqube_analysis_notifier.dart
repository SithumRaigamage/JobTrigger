import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_analysis.dart';

part 'sonarqube_analysis_notifier.g.dart';

/// A project's analysis history (`US-SQ-QUALITY-04`), keyed by project key.
@riverpod
class SonarQubeAnalysisNotifier extends _$SonarQubeAnalysisNotifier {
  @override
  Future<List<SonarQubeAnalysis>> build(String projectKey) async {
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchAnalysisHistory(projectKey);
    return result.fold((analyses) => analyses, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
