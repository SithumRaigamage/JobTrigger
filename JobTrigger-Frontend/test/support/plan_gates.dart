import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/presentation/features/subscription/plan_gate.dart';

import 'fake_subscription.dart';

/// P20-25: billing on, on the Free plan (1 server, 3 pins, no Pro features).
final freeGate = PlanGate(
  active: true,
  entitlements: freeSnapshot.entitlements,
);

/// Billing on, on Pro.
final proGate = PlanGate(active: true, entitlements: proSnapshot.entitlements);

Override gateOverride(PlanGate gate) =>
    planGateProvider.overrideWithValue(gate);

JenkinsServer jenkinsServerNamed(String id) => JenkinsServer(
  id: id,
  serverName: id,
  jenkinsURL: 'https://$id.test',
  username: 'u',
  secret: 's',
);

GitHubCredential gitHubCredentialNamed(String id) =>
    GitHubCredential(id: id, label: id, secret: 't');

SonarQubeCredential sonarQubeCredentialNamed(String id) => SonarQubeCredential(
  id: id,
  label: id,
  baseUrl: 'https://$id.test',
  secret: 't',
);

class _Jenkins extends CredentialsNotifier {
  _Jenkins(this.list);
  final List<JenkinsServer> list;
  @override
  Future<List<JenkinsServer>> build() async => list;
}

class _GitHub extends GitHubCredentialsNotifier {
  _GitHub(this.list);
  final List<GitHubCredential> list;
  @override
  Future<List<GitHubCredential>> build() async => list;
}

class _Sonar extends SonarQubeCredentialsNotifier {
  _Sonar(this.list);
  final List<SonarQubeCredential> list;
  @override
  Future<List<SonarQubeCredential>> build() async => list;
}

/// The saved-credential lists, as the three tools' notifiers hold them.
List<Override> savedCredentials({
  List<JenkinsServer> jenkins = const [],
  List<GitHubCredential> github = const [],
  List<SonarQubeCredential> sonarqube = const [],
}) => [
  credentialsNotifierProvider.overrideWith(() => _Jenkins(jenkins)),
  gitHubCredentialsNotifierProvider.overrideWith(() => _GitHub(github)),
  sonarQubeCredentialsNotifierProvider.overrideWith(() => _Sonar(sonarqube)),
];
