import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// US-GH-CRED-03 "Active GitHub credential is independent of active
/// Jenkins server": two separate choices, each on this device only.
const _jenkins = JenkinsServer(
  id: 'j1',
  serverName: 'Jenkins',
  jenkinsURL: 'https://ci.test',
  username: 'u',
  secret: 'fixture-secret',
);
const _a = GitHubCredential(id: 'g1', label: 'A', secret: 'fixture-a');
const _b = GitHubCredential(id: 'g2', label: 'B', secret: 'fixture-b');

class _Servers extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async => const [_jenkins];
}

class _GitHub extends GitHubCredentialsNotifier {
  @override
  Future<List<GitHubCredential>> build() async => const [_a, _b];
}

void main() {
  test('switching GitHub credentials leaves the Jenkins server alone, and '
      'back', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        credentialsNotifierProvider.overrideWith(_Servers.new),
        gitHubCredentialsNotifierProvider.overrideWith(_GitHub.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(activeServerNotifierProvider, (_, _) {});
    container.listen(activeGitHubCredentialNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(activeServerNotifierProvider)?.id, 'j1');

    await container
        .read(activeGitHubCredentialNotifierProvider.notifier)
        .setActiveCredential(_b);
    expect(container.read(activeGitHubCredentialNotifierProvider)?.id, 'g2');
    expect(container.read(activeServerNotifierProvider)?.id, 'j1');

    await container
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(_jenkins);
    expect(container.read(activeGitHubCredentialNotifierProvider)?.id, 'g2');
  });
}
