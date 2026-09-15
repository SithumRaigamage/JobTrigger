import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_credentials_repository_impl.dart';
import '../../../domain/credential/github_credential.dart';

part 'github_credentials_notifier.g.dart';

/// List of saved GitHub credentials — mirrors `CredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.
@riverpod
class GitHubCredentialsNotifier extends _$GitHubCredentialsNotifier {
  @override
  Future<List<GitHubCredential>> build() async {
    final result = await ref
        .watch(gitHubCredentialsRepositoryProvider)
        .fetchAll();
    return result.fold((credentials) => credentials, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
