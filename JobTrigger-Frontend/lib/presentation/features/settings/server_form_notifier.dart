import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/credentials_repository_impl.dart';
import 'credentials_notifier.dart';

part 'server_form_notifier.g.dart';

/// Add/edit form submit state — see `docs/state-management.md`'s "Feature:
/// settings / server management" section. Same shape as
/// `LoginNotifier`/`SignupNotifier`: form field values are passed in at
/// call time (owned by the widget's `TextEditingController`s), not stored
/// on the notifier.
@riverpod
class ServerFormNotifier extends _$ServerFormNotifier {
  @override
  FutureOr<void> build() {}

  /// [id] is null when adding a new server, non-null when editing one.
  Future<void> save({
    String? id,
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    required bool isDefault,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(credentialsRepositoryProvider);
    final result = id == null
        ? await repository.add(
            serverName: serverName,
            jenkinsURL: jenkinsURL,
            username: username,
            secret: secret,
            paramToken: paramToken,
            isDefault: isDefault,
          )
        : await repository.update(
            id,
            serverName: serverName,
            jenkinsURL: jenkinsURL,
            username: username,
            secret: secret,
            paramToken: paramToken,
            isDefault: isDefault,
          );

    switch (result) {
      case Ok():
        await ref.read(credentialsNotifierProvider.notifier).refresh();
        state = const AsyncData(null);
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}
