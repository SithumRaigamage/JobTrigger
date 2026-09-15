import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_credentials_repository_impl.dart';
import 'active_sonarqube_credential_notifier.dart';
import 'sonarqube_credentials_notifier.dart';

part 'sonarqube_credential_form_notifier.g.dart';

/// Add/edit form submit state — mirrors `GitHubCredentialFormNotifier`'s
/// shape exactly, including setting a newly-saved `isDefault: true`
/// credential as active immediately (not just flagging it and hoping a
/// future rehydrate picks it up — the fix `GitHubCredentialFormNotifier`
/// needed after the fact, built in here from day one). Form field values
/// are passed in at call time (owned by the widget's `TextEditingController`s),
/// not stored on the notifier.
@riverpod
class SonarQubeCredentialFormNotifier extends _$SonarQubeCredentialFormNotifier {
  @override
  FutureOr<void> build() {}

  /// [id] is null when adding a new credential, non-null when editing one.
  Future<void> save({
    String? id,
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    required bool isDefault,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(sonarQubeCredentialsRepositoryProvider);
    final result = id == null
        ? await repository.add(
            label: label,
            baseUrl: baseUrl,
            secret: secret,
            defaultOrganization: defaultOrganization,
            isDefault: isDefault,
          )
        : await repository.update(
            id,
            label: label,
            baseUrl: baseUrl,
            secret: secret,
            defaultOrganization: defaultOrganization,
            isDefault: isDefault,
          );

    switch (result) {
      case Ok(:final value):
        await ref.read(sonarQubeCredentialsNotifierProvider.notifier).refresh();
        if (isDefault) {
          await ref
              .read(activeSonarQubeCredentialNotifierProvider.notifier)
              .setActiveCredential(value);
        }
        state = const AsyncData(null);
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}
