import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_branch_ref.dart';
import '../../../domain/sonarqube/sonarqube_quality_gate.dart';
import '../../../domain/sonarqube/sonarqube_server_info.dart';

part 'sonarqube_quality_notifiers.g.dart';

/// A project's quality gate (`US-SQ-QUALITY-01`), keyed by project key.
@riverpod
class SonarQubeQualityGateNotifier extends _$SonarQubeQualityGateNotifier {
  @override
  Future<SonarQubeQualityGate> build(String projectKey) async {
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchQualityGate(projectKey);
    return result.fold((gate) => gate, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// A project's key measures (`US-SQ-QUALITY-02`): metric → value, with
/// metrics the server didn't compute absent.
@riverpod
class SonarQubeMeasuresNotifier extends _$SonarQubeMeasuresNotifier {
  @override
  Future<Map<String, String>> build(String projectKey) async {
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchMeasures(projectKey);
    return result.fold((measures) => measures, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// The branch and pull-request choices for a project (`US-SQ-QUALITY-10`).
@riverpod
Future<SonarQubeRefChoices> sonarQubeProjectRefs(
  Ref ref,
  String projectKey,
) async {
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchProjectRefs(projectKey);
  return result.fold((choices) => choices, (failure) => throw failure);
}

/// The server's version and status (`US-SQ-SERVER-01`), for telling a server
/// problem from an app problem.
@riverpod
Future<SonarQubeServerInfo> sonarQubeServerInfo(Ref ref) async {
  final result = await ref.watch(sonarQubeRepositoryProvider).fetchServerInfo();
  return result.fold((info) => info, (failure) => throw failure);
}
