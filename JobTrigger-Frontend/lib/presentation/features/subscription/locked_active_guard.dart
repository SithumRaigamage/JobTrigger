import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../data/credentials/active_github_credential_notifier.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/credentials/credential_secrets.dart';
import '../../../data/credentials/credentials_notifier.dart';
import '../../../data/credentials/github_credentials_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../tool_selection/ci_tool.dart';
import 'plan_gate.dart';

part 'locked_active_guard.g.dart';

/// P20-25: after a downgrade the backend marks credentials beyond the plan
/// as locked. If the *active* Jenkins server, GitHub credential or
/// SonarQube credential is one of them, this switches to the first unlocked
/// one (or to none), deletes the locked one's cached secret from secure
/// storage, and remembers the tool, so the next time the user opens it the
/// paywall opens with reason `locked` (see [consume]).
///
/// Billing on only: with billing off (or demo) the plan gate is inactive,
/// the credential lists are not even watched, and nothing here runs.
/// Watched from `main.dart`.
@Riverpod(keepAlive: true)
class LockedActiveGuard extends _$LockedActiveGuard {
  /// The tools whose active credential was locked and replaced.
  @override
  Set<CiTool> build() {
    if (!ref.watch(planGateProvider).active) return const {};
    // The list loads first and the active one resolves after it, so both
    // are watched; each change re-checks all three tools.
    for (final provider in <ProviderListenable<Object?>>[
      credentialsNotifierProvider,
      gitHubCredentialsNotifierProvider,
      sonarQubeCredentialsNotifierProvider,
      activeServerNotifierProvider,
      activeGitHubCredentialNotifierProvider,
      activeSonarQubeCredentialNotifierProvider,
    ]) {
      ref.listen(provider, (_, _) => unawaited(Future.microtask(_check)));
    }
    unawaited(Future.microtask(_check));
    return const {};
  }

  /// True once, if [tool]'s active credential was locked since it was last
  /// opened; the caller opens the paywall for `locked`.
  bool consume(CiTool tool) {
    if (!state.contains(tool)) return false;
    state = {...state}..remove(tool);
    return true;
  }

  Future<void> _check() async {
    if (!ref.mounted) return;
    final storage = ref.read(secureStorageProvider);

    final servers = ref.read(credentialsNotifierProvider).value;
    final server = ref.read(activeServerNotifierProvider);
    if (servers != null && server != null && server.locked) {
      final next = servers.where((s) => !s.locked).firstOrNull;
      final notifier = ref.read(activeServerNotifierProvider.notifier);
      await (next == null ? notifier.clear() : notifier.setActiveServer(next));
      await CredentialSecrets.forgetStored(storage, 'jenkins', server.id);
      _remember(CiTool.jenkins);
    }

    final githubs = ref.read(gitHubCredentialsNotifierProvider).value;
    final github = ref.read(activeGitHubCredentialNotifierProvider);
    if (githubs != null && github != null && github.locked) {
      final next = githubs.where((c) => !c.locked).firstOrNull;
      final notifier = ref.read(
        activeGitHubCredentialNotifierProvider.notifier,
      );
      await (next == null
          ? notifier.clear()
          : notifier.setActiveCredential(next));
      await CredentialSecrets.forgetStored(storage, 'github', github.id);
      _remember(CiTool.githubActions);
    }

    final sonars = ref.read(sonarQubeCredentialsNotifierProvider).value;
    final sonar = ref.read(activeSonarQubeCredentialNotifierProvider);
    if (sonars != null && sonar != null && sonar.locked) {
      final next = sonars.where((c) => !c.locked).firstOrNull;
      final notifier = ref.read(
        activeSonarQubeCredentialNotifierProvider.notifier,
      );
      await (next == null
          ? notifier.clear()
          : notifier.setActiveCredential(next));
      await CredentialSecrets.forgetStored(storage, 'sonarqube', sonar.id);
      _remember(CiTool.sonarqube);
    }
  }

  void _remember(CiTool tool) {
    if (ref.mounted) state = {...state, tool};
  }
}
