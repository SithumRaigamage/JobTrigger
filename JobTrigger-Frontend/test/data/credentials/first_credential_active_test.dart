import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The first credential saved becomes the active one, for GitHub and
/// SonarQube as for Jenkins (US-CRED-02), without "Set as default". Before
/// the fix nothing was active until a restart.
List<GitHubCredential> _gitHub = const [];
List<SonarQubeCredential> _sonar = const [];

class _GitHubList extends GitHubCredentialsNotifier {
  @override
  Future<List<GitHubCredential>> build() async => _gitHub;
}

class _SonarList extends SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async => _sonar;
}

Future<void> _settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the first GitHub credential saved becomes active', () async {
    _gitHub = const [];
    final c = ProviderContainer(
      overrides: [
        gitHubCredentialsNotifierProvider.overrideWith(_GitHubList.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(gitHubCredentialsNotifierProvider, (_, _) {});
    c.listen(activeGitHubCredentialNotifierProvider, (_, _) {});
    await _settle();
    expect(c.read(activeGitHubCredentialNotifierProvider), isNull);

    _gitHub = const [
      GitHubCredential(id: 'g1', label: 'Personal', secret: 'fixture-a'),
    ];
    await c.read(gitHubCredentialsNotifierProvider.notifier).refresh();
    await _settle();

    expect(c.read(activeGitHubCredentialNotifierProvider)?.id, 'g1');
  });

  test('the first SonarQube credential saved becomes active', () async {
    _sonar = const [];
    final c = ProviderContainer(
      overrides: [
        sonarQubeCredentialsNotifierProvider.overrideWith(_SonarList.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(sonarQubeCredentialsNotifierProvider, (_, _) {});
    c.listen(activeSonarQubeCredentialNotifierProvider, (_, _) {});
    await _settle();
    expect(c.read(activeSonarQubeCredentialNotifierProvider), isNull);

    _sonar = const [
      SonarQubeCredential(
        id: 's1',
        label: 'SonarCloud',
        baseUrl: 'https://sonarcloud.io',
        secret: 'fixture-b',
      ),
    ];
    await c.read(sonarQubeCredentialsNotifierProvider.notifier).refresh();
    await _settle();

    expect(c.read(activeSonarQubeCredentialNotifierProvider)?.id, 's1');
  });
}
