import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_tool_link.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_gate_link_card.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_tool_links_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/sonarqube_insights_defaults.dart';

const _api = SonarQubeProject(key: 'api', name: 'API', lastAnalysisDate: null);
const _jobUrl = 'https://ci/job/api/';

class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async => const Ok(SonarQubeProjectsPage(projects: [_api], total: 1));

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) async => const Ok(
    SonarQubeQualityGate(state: QualityGateState.failed, conditions: []),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c1',
    label: 'L',
    baseUrl: 'http://s',
    secret: 't',
  );
}

class _None extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => null;
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool credential = true,
  SonarQubeLinkedTool tool = SonarQubeLinkedTool.jenkins,
  String id = _jobUrl,
}) async {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      activeSonarQubeCredentialNotifierProvider.overrideWith(
        credential ? _Credential.new : _None.new,
      ),
      sonarQubeRepositoryProvider.overrideWithValue(_Repo()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SonarQubeGateLinkCard(tool: tool, externalId: id),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'active_sonarqube_credential_id': 'c1',
    }),
  );

  test('a build URL maps to its job; a job URL to itself', () {
    expect(
      jenkinsJobUrlFromBuildUrl('https://ci/job/team/job/api/42/'),
      'https://ci/job/team/job/api/',
    );
    expect(
      jenkinsJobUrlFromBuildUrl('https://ci/job/api/42'),
      'https://ci/job/api/',
    );
    expect(jenkinsJobUrlFromBuildUrl(_jobUrl), _jobUrl);
    // A job whose name is a number is still only stripped once.
    expect(
      jenkinsJobUrlFromBuildUrl('https://ci/job/2024/7/'),
      'https://ci/job/2024/',
    );
  });

  testWidgets('with no SonarQube credential nothing is drawn '
      '(US-SQ-XTOOL-01)', (tester) async {
    await _pump(tester, credential: false);
    expect(find.text('Link a SonarQube project'), findsNothing);
  });

  testWidgets('a device that never set SonarQube up reads nothing from it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // The credential provider would throw if anything read it.
    final container = ProviderContainer(
      overrides: [
        activeSonarQubeCredentialNotifierProvider.overrideWith(
          () => throw StateError('must not be read'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SonarQubeGateLinkCard(
              tool: SonarQubeLinkedTool.github,
              externalId: 'acme/api',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets(
    'a configured device with a credential that is gone draws nothing',
    (tester) async {
      await _pump(tester, credential: false);
      expect(find.text('SonarQube quality gate'.toUpperCase()), findsNothing);
      expect(find.text('Link a SonarQube project'), findsNothing);
    },
  );

  testWidgets('link once, then the gate shows beside the build, unlink '
      'confirms (US-SQ-XTOOL-01)', (tester) async {
    final container = await _pump(tester);
    expect(find.text('Link a SonarQube project'), findsOneWidget);
    expect(find.text('Stored on this device only.'), findsOneWidget);

    await tester.tap(find.text('Link a SonarQube project'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('API'));
    await tester.pumpAndSettle();

    expect(find.text('Failed'), findsOneWidget);
    expect(
      container
          .read(sonarQubeToolLinksNotifierProvider)
          .values
          .single
          .projectKey,
      'api',
    );
    // Remembered on the device, nothing but the project's key and name.
    final saved = (await SharedPreferences.getInstance()).getString(
      'sonarqube_links_c1',
    )!;
    expect(saved, contains('"api"'));
    expect(saved, isNot(contains('http://s')));

    await tester.tap(find.byTooltip('Unlink SonarQube project'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Unlink'));
    await tester.pumpAndSettle();
    expect(find.text('Link a SonarQube project'), findsOneWidget);
  });

  testWidgets('a GitHub link and a Jenkins link are separate', (tester) async {
    SharedPreferences.setMockInitialValues({
      'active_sonarqube_credential_id': 'c1',
      'sonarqube_links_c1': '{"github|acme/api":{"key":"api","name":"API"}}',
    });
    final container = await _pump(tester);
    // The same project is linked for GitHub, not for this Jenkins job.
    expect(find.text('Link a SonarQube project'), findsOneWidget);
    expect(container.read(sonarQubeJenkinsJobsForProvider('api')), isEmpty);
  });

  testWidgets('"Scan now" finds the linked Jenkins job (US-SQ-XTOOL-02)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'active_sonarqube_credential_id': 'c1',
      'sonarqube_links_c1': '{"jenkins|$_jobUrl":{"key":"api","name":"API"}}',
    });
    final container = await _pump(tester);
    await tester.pumpAndSettle();
    expect(container.read(sonarQubeJenkinsJobsForProvider('api')), [_jobUrl]);
    expect(container.read(sonarQubeJenkinsJobsForProvider('other')), isEmpty);
  });
}
