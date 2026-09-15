import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_credentials_repository_impl.dart';
import 'active_github_credential_notifier.dart';
import 'github_credentials_notifier.dart';

part 'github_credential_form_notifier.g.dart';

/// Add/edit form submit state — mirrors `ServerFormNotifier`'s shape
/// exactly. Form field values are passed in at call time (owned by the
/// widget's `TextEditingController`s), not stored on the notifier.
@riverpod
class GitHubCredentialFormNotifier extends _$GitHubCredentialFormNotifier {
  @override
  FutureOr<void> build() {}

  /// [id] is null when adding a new credential, non-null when editing one.
  Future<void> save({
    String? id,
    required String label,
    required String secret,
    String? defaultOwner,
    required bool isDefault,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(gitHubCredentialsRepositoryProvider);
    final result = id == null
        ? await repository.add(
            label: label,
            secret: secret,
            defaultOwner: defaultOwner,
            isDefault: isDefault,
          )
        : await repository.update(
            id,
            label: label,
            secret: secret,
            defaultOwner: defaultOwner,
            isDefault: isDefault,
          );

    switch (result) {
      case Ok(:final value):
        await ref.read(gitHubCredentialsNotifierProvider.notifier).refresh();
        // Mirrors ServerFormNotifier.save()'s fix: saving with the default
        // toggle on should mean "use this one now," not just flag it and
        // hope a future rehydrate picks it up.
        if (isDefault) {
          await ref
              .read(activeGitHubCredentialNotifierProvider.notifier)
              .setActiveCredential(value);
        }
        state = const AsyncData(null);
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}
