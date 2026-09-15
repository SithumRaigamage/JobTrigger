import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_credentials_repository_impl.dart';
import '../../../domain/credential/sonarqube_credential.dart';

part 'sonarqube_credentials_notifier.g.dart';

/// List of saved SonarQube credentials — mirrors `GitHubCredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.
@riverpod
class SonarQubeCredentialsNotifier extends _$SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async {
    final result = await ref
        .watch(sonarQubeCredentialsRepositoryProvider)
        .fetchAll();
    return result.fold(
      (credentials) => credentials,
      (failure) => throw failure,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
