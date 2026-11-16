import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/presentation/features/subscription/locked_active_guard.dart';
import 'package:job_trigger/presentation/features/subscription/plan_gate.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/plan_gates.dart';

const _lockedServer = JenkinsServer(
  id: 'a',
  serverName: 'a',
  jenkinsURL: 'https://a.test',
  username: 'u',
  secret: 's',
  locked: true,
);
const _lockedGitHub = GitHubCredential(
  id: 'a',
  label: 'a',
  secret: 't',
  locked: true,
);
const _lockedSonar = SonarQubeCredential(
  id: 'a',
  label: 'a',
  baseUrl: 'https://a.test',
  secret: 't',
  locked: true,
);

class _ActiveServer extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => _lockedServer;
}

class _ActiveGitHub extends ActiveGitHubCredentialNotifier {
  @override
  GitHubCredential? build() => _lockedGitHub;
}

class _ActiveSonar extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => _lockedSonar;
}

const _secretKeys = {
  'credential_secret_jenkins_a': 'x',
  'credential_secret_github_a': 'x',
  'credential_secret_sonarqube_a': 'x',
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({..._secretKeys});
  });

  Future<ProviderContainer> run(
    PlanGate gate, {
    bool hasUnlocked = true,
  }) async {
    final c = ProviderContainer(
      overrides: [
        gateOverride(gate),
        ...savedCredentials(
          jenkins: [_lockedServer, if (hasUnlocked) jenkinsServerNamed('b')],
          github: [_lockedGitHub, if (hasUnlocked) gitHubCredentialNamed('b')],
          sonarqube: [
            _lockedSonar,
            if (hasUnlocked) sonarQubeCredentialNamed('b'),
          ],
        ),
        activeServerNotifierProvider.overrideWith(_ActiveServer.new),
        activeGitHubCredentialNotifierProvider.overrideWith(_ActiveGitHub.new),
        activeSonarQubeCredentialNotifierProvider.overrideWith(
          _ActiveSonar.new,
        ),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(activeServerNotifierProvider, (_, _) {})
      ..listen(activeGitHubCredentialNotifierProvider, (_, _) {})
      ..listen(activeSonarQubeCredentialNotifierProvider, (_, _) {})
      ..listen(lockedActiveGuardProvider, (_, _) {});
    await pumpEventQueue();
    return c;
  }

  Future<bool> hasSecret(String tool) async =>
      (await const FlutterSecureStorage().read(
        key: 'credential_secret_${tool}_a',
      )) !=
      null;

  test('Jenkins: the locked active server is replaced by the first unlocked '
      'one, its secret is deleted, and the paywall is owed', () async {
    final c = await run(freeGate);
    expect(c.read(activeServerNotifierProvider)?.id, 'b');
    expect(await hasSecret('jenkins'), isFalse);
    expect(c.read(lockedActiveGuardProvider), contains(CiTool.jenkins));
    final guard = c.read(lockedActiveGuardProvider.notifier);
    expect(guard.consume(CiTool.jenkins), isTrue);
    expect(guard.consume(CiTool.jenkins), isFalse); // only once
  });

  test('GitHub: the same', () async {
    final c = await run(freeGate);
    expect(c.read(activeGitHubCredentialNotifierProvider)?.id, 'b');
    expect(await hasSecret('github'), isFalse);
    expect(
      c.read(lockedActiveGuardProvider.notifier).consume(CiTool.githubActions),
      isTrue,
    );
  });

  test('SonarQube: the same', () async {
    final c = await run(freeGate);
    expect(c.read(activeSonarQubeCredentialNotifierProvider)?.id, 'b');
    expect(await hasSecret('sonarqube'), isFalse);
    expect(
      c.read(lockedActiveGuardProvider.notifier).consume(CiTool.sonarqube),
      isTrue,
    );
  });

  test('with nothing unlocked left, each tool ends with no active '
      'credential', () async {
    final c = await run(freeGate, hasUnlocked: false);
    expect(c.read(activeServerNotifierProvider), isNull);
    expect(c.read(activeGitHubCredentialNotifierProvider), isNull);
    expect(c.read(activeSonarQubeCredentialNotifierProvider), isNull);
    expect(c.read(lockedActiveGuardProvider), hasLength(3));
  });

  test('billing off: a locked active credential is left exactly as it '
      'was', () async {
    final c = await run(PlanGate.open);
    expect(c.read(activeServerNotifierProvider)?.id, 'a');
    expect(c.read(activeGitHubCredentialNotifierProvider)?.id, 'a');
    expect(c.read(activeSonarQubeCredentialNotifierProvider)?.id, 'a');
    expect(await hasSecret('jenkins'), isTrue);
    expect(await hasSecret('github'), isTrue);
    expect(await hasSecret('sonarqube'), isTrue);
    expect(c.read(lockedActiveGuardProvider), isEmpty);
  });
}
