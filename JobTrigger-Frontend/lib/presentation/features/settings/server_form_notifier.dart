import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/credentials_repository_impl.dart';
import '../../../domain/auth/auth_validation.dart';
import '../../../domain/credential/jenkins_url.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/credentials_notifier.dart';

import '../subscription/plan_gate.dart';
import '../tool_selection/ci_tool.dart';

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
  /// [needsReentry] is true when the stored secret could not be decrypted
  /// (AUD-63) — see `JenkinsServer.needsReentry`.
  Future<void> save({
    String? id,
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    required bool isDefault,
    bool needsReentry = false,
  }) async {
    // AUD-63: the stored secret couldn't be decrypted, so there is nothing
    // to keep — the user has to type it again. Sending an empty secret
    // would overwrite the stored one with a blank and quietly break the
    // credential for good.
    if (needsReentry && secret.trim().isEmpty) {
      state = AsyncError(
        const FormValidationError(
          'Enter the secret again — it could not be read from the server.',
        ),
        StackTrace.current,
      );
      return;
    }
    // AUD-14: refuse an unusable URL before it reaches the backend.
    final urlProblem = jenkinsUrlProblem(jenkinsURL);
    if (urlProblem != null) {
      state = AsyncError(FormValidationError(urlProblem), StackTrace.current);
      return;
    }
    jenkinsURL = normalizeJenkinsUrl(jenkinsURL);
    state = const AsyncLoading();
    // P20-25: a new server over the plan's limit goes to the paywall
    // instead of the backend (which would refuse it the same way).
    if (id == null) {
      final blocked = await addCredentialBlock(ref, CiTool.jenkins);
      if (blocked != null) {
        state = AsyncError(blocked, StackTrace.current);
        return;
      }
    }
    // US-CRED-02: the backend requires these (`JenkinsCredential` schema);
    // say so here instead of after a round trip. After the plan check, so
    // a server over the limit still goes straight to the paywall.
    final missing = serverName.trim().isEmpty
        ? 'Enter a name for this server.'
        : username.trim().isEmpty
        ? 'Enter your Jenkins username.'
        // An edit keeps its existing rules (AUD-63 above); only a new server
        // must bring a secret.
        : id == null && secret.isEmpty
        ? 'Enter your API token or password.'
        : null;
    if (missing != null) {
      state = AsyncError(FormValidationError(missing), StackTrace.current);
      return;
    }
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
      case Ok(:final value):
        await ref.read(credentialsNotifierProvider.notifier).refresh();
        // "Set as default" only ever wrote the backend's `isDefault` flag —
        // the locally-active server (what `jenkinsClientProvider` actually
        // uses) never followed unless this was the very first server ever
        // saved or the user separately tapped the row in the server list.
        // Saving with the toggle on should mean "use this one now," not
        // "flag it and hope a future rehydrate picks it up."
        if (isDefault) {
          await ref
              .read(activeServerNotifierProvider.notifier)
              .setActiveServer(value);
        }
        state = const AsyncData(null);
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}
