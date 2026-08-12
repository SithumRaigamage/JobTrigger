import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/credentials_repository_impl.dart';
import '../../../domain/credential/jenkins_server.dart';

part 'credentials_notifier.g.dart';

/// List of saved Jenkins servers — see `docs/state-management.md`'s
/// "Feature: settings / server management" section. Follows the standard
/// shape from `docs/architecture.md §4`.
@riverpod
class CredentialsNotifier extends _$CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async {
    final result = await ref.watch(credentialsRepositoryProvider).fetchAll();
    return result.fold((servers) => servers, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
