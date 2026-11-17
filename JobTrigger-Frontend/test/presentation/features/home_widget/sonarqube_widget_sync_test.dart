import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/biometric_service.dart';
import 'package:job_trigger/core/platform/home_widget_bridge.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/domain/widget/widget_snapshot.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home_widget/sonarqube_widget_sync.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_pins_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_biometric_service.dart';
import '../../../support/fake_home_widget_bridge.dart';
import '../../../support/sonarqube_insights_defaults.dart';

class _Pins extends SonarQubePinsNotifier {
  @override
  List<PinnedSonarQubeProject> build() => const [
    PinnedSonarQubeProject(key: 'acme:api', name: 'API'),
  ];
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c1',
    label: 'L',
    baseUrl: 'http://sonar.example:9000',
    secret: 'squ_secret',
  );
}

class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async => Ok({
    for (final k in projectKeys)
      k: const SonarQubeProjectSummary(gate: QualityGateState.failed),
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeHomeWidgetBridge bridge;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    bridge = FakeHomeWidgetBridge();
  });

  Future<ProviderContainer> container() async {
    final c = ProviderContainer(
      overrides: [
        biometricServiceProvider.overrideWithValue(FakeBiometricService()),
        homeWidgetBridgeProvider.overrideWithValue(bridge),
        sonarQubePinsNotifierProvider.overrideWith(_Pins.new),
        activeSonarQubeCredentialNotifierProvider.overrideWith(_Credential.new),
        sonarQubeRepositoryProvider.overrideWithValue(_Repo()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authNotifierProvider.future);
    c.listen(sonarQubeWidgetSyncProvider, (_, _) {});
    return c;
  }

  test('signed out, nothing reaches the widget', () async {
    await container();
    await pumpEventQueue();
    expect(bridge.writtenSonarQube, isEmpty);
  });

  test('a pinned project\'s verdict reaches the widget, with no credential '
      '(US-SQ-WIDGET-01)', () async {
    final c = await container();
    await c
        .read(authNotifierProvider.notifier)
        .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt');
    await pumpEventQueue();

    final row = bridge.writtenSonarQube.last.jobs.single;
    expect(row.label, 'API');
    expect(row.status, WidgetJobStatus.failure);
    expect(row.statusText, 'Failed');
    expect(row.link, contains('/sonarqube/project?key=acme%3Aapi'));
    final json = bridge.writtenSonarQube.last.toJson().toString();
    expect(json, isNot(contains('squ_secret')));
    expect(json, isNot(contains('sonar.example')));
    // The Jenkins widget's snapshot is untouched.
    expect(bridge.written, isEmpty);
  });

  test('with the app lock on, the widget shows only a count', () async {
    SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
    final c = await container();
    await c
        .read(authNotifierProvider.notifier)
        .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt');
    await pumpEventQueue();

    expect(bridge.writtenSonarQube, isNotEmpty);
    for (final snapshot in bridge.writtenSonarQube) {
      expect(snapshot.jobs, isEmpty);
      expect(snapshot.lockedCount, 1);
    }
  });
}
