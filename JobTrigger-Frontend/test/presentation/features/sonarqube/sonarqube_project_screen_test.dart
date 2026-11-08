import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_screen.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';

class _Repo implements SonarQubeRepository {
  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) async {
    historyAsked.add(projectKey);
    return history;
  }

  _Repo(this.result);

  Result<List<SonarQubeProject>, AppFailure> result;
  int calls = 0;

  /// What the per-project history lookup answers (a project whose list entry
  /// has no date). Empty by default: genuinely never analysed.
  Result<List<SonarQubeAnalysis>, AppFailure> history = const Ok([]);
  final List<String> historyAsked = [];

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async {
    calls++;
    return switch (result) {
      Ok(:final value) => Ok(
        SonarQubeProjectsPage(projects: value, total: value.length),
      ),
      Err(:final error) => Err(error),
    };
  }

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();
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

/// The saved list, loaded and empty: there really is no credential.
class _NoSavedCredentials extends SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async => const [];
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
        sonarQubeCredentialsNotifierProvider.overrideWith(
          _NoSavedCredentials.new,
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

  group('last analysis when the list has no date', () {
    testWidgets('is taken from the analysis history, not called "never"', (
      tester,
    ) async {
      final repo =
          _Repo(
              const Ok([
                SonarQubeProject(
                  key: 'k',
                  name: 'Silent',
                  lastAnalysisDate: null,
                ),
              ]),
            )
            ..history = Ok([
              SonarQubeAnalysis(
                key: 'a',
                date: DateTime.now().subtract(const Duration(hours: 2)),
                projectVersion: null,
              ),
            ]);

      await _pump(tester, repo);

      expect(find.text('Analyzed 2h ago'), findsOneWidget);
      expect(find.text('Never analyzed'), findsNothing);
      expect(repo.historyAsked, ['k']);
    });

    testWidgets('a project that has a date does not ask for the history', (
      tester,
    ) async {
      final repo = _Repo(Ok(_projects));

      await _pump(tester, repo);

      // Only the one without a date is looked up.
      expect(repo.historyAsked, ['acme:web']);
    });

    testWidgets('a failed lookup says it is unknown, not "never analyzed"', (
      tester,
    ) async {
      final repo = _Repo(
        const Ok([
          SonarQubeProject(key: 'k', name: 'Silent', lastAnalysisDate: null),
        ]),
      )..history = const Err(NetworkFailure());

      await _pump(tester, repo);

      expect(find.text('Last analysis unknown'), findsOneWidget);
      expect(find.text('Never analyzed'), findsNothing);
    });
  });
}
