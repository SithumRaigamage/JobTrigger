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
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_screen.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';

class _Repo implements SonarQubeRepository {
  _Repo(this.result);

  Result<List<SonarQubeProject>, AppFailure> result;
  int calls = 0;

  @override
  Future<Result<List<SonarQubeProject>, AppFailure>> fetchProjects() async {
    calls++;
    return result;
  }
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c',
    label: 'acme-sonar',
    baseUrl: 'https://sonar.test',
    secret: 't',
  );
}

class _NoCredential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => null;
}

Future<void> _pump(
  WidgetTester tester,
  _Repo repo, {
  bool credential = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        activeSonarQubeCredentialNotifierProvider.overrideWith(
          credential ? _Credential.new : _NoCredential.new,
        ),
        sonarQubeRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeProjectScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _projects = [
  SonarQubeProject(
    key: 'acme:api',
    name: 'API Gateway',
    lastAnalysisDate: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  const SonarQubeProject(
    key: 'acme:web',
    name: 'Web App',
    lastAnalysisDate: null,
  ),
];

void main() {
  test('SonarQube is a selectable tool', () {
    expect(CiTool.sonarqube.isAvailable, isTrue);
  });

  testWidgets('lists projects with key and last analysis', (tester) async {
    await _pump(tester, _Repo(Ok(_projects)));

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('acme-sonar'), findsOneWidget);
    expect(find.text('API Gateway'), findsOneWidget);
    expect(find.text('acme:api'), findsOneWidget);
    expect(find.text('Analyzed 3h ago'), findsOneWidget);
    expect(find.text('Web App'), findsOneWidget);
    expect(find.text('Never analyzed'), findsOneWidget);
  });

  testWidgets('search matches name or key, and says when nothing matches', (
    tester,
  ) async {
    await _pump(tester, _Repo(Ok(_projects)));

    await tester.enterText(find.byType(TextField), 'gateway');
    await tester.pump();
    expect(find.text('API Gateway'), findsOneWidget);
    expect(find.text('Web App'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ACME:WEB');
    await tester.pump();
    expect(find.text('Web App'), findsOneWidget);
    expect(find.text('API Gateway'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No results for "zzz"'), findsOneWidget);
  });

  testWidgets('no projects says so', (tester) async {
    await _pump(tester, _Repo(const Ok([])));

    expect(find.text('No projects found'), findsOneWidget);
  });

  testWidgets('a wrong SonarCloud organization is explained, with retry', (
    tester,
  ) async {
    final repo = _Repo(const Err(SonarQubeOrganizationNotFoundFailure()));
    await _pump(tester, repo);
    expect(find.textContaining('organization'), findsOneWidget);

    repo.result = Ok(_projects);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();

    expect(find.text('API Gateway'), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('with no credential, it asks for one instead of fetching', (
    tester,
  ) async {
    final repo = _Repo(Ok(_projects));
    await _pump(tester, repo, credential: false);

    expect(find.text('No SonarQube Credential'), findsOneWidget);
    expect(repo.calls, 0);
  });
}
