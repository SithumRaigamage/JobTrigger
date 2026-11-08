import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_issue_screen.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_issues_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

class _Repo implements SonarQubeRepository {
  Result<SonarQubeIssueContext, AppFailure> context = const Ok(
    SonarQubeIssueContext(
      ruleName: 'Track uses of TODO tags',
      snippet: [
        SonarQubeSourceLine(number: 9, code: 'int a = 1;'),
        SonarQubeSourceLine(number: 10, code: '// TODO fix'),
        SonarQubeSourceLine(number: 11, code: 'return a;'),
      ],
    ),
  );
  int contextCalls = 0;
  Result<SonarQubeIssuePage, AppFailure>? issues;

  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) async {
    contextCalls++;
    return context;
  }

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) async => issues ?? Ok(SonarQubeIssuePage(issues: [_issue()], total: 1));

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) => throw UnimplementedError();

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) => throw UnimplementedError();
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c',
    label: 'Local',
    baseUrl: 'http://192.168.1.53:9000',
    secret: 't',
  );
}

const _project = SonarQubeProject(
  key: 'JobTrigger',
  name: 'JobTrigger',
  lastAnalysisDate: null,
);

SonarQubeIssue _issue({
  String? rule = 'java:S1135',
  int? line = 10,
  List<String> tags = const ['todo', 'convention'],
}) => SonarQubeIssue(
  key: 'AX-1',
  type: 'CODE_SMELL',
  severity: 'INFO',
  message: 'Complete the task associated to this TODO comment.',
  file: 'src/Foo.java',
  line: line,
  component: 'JobTrigger:src/Foo.java',
  rule: rule,
  effort: '15min',
  tags: tags,
  author: 'dev@example.com',
  status: 'OPEN',
  creationDate: DateTime.now().subtract(const Duration(days: 3)),
);

Future<void> _pump(
  WidgetTester tester,
  _Repo repo,
  SonarQubeIssue issue, {
  List<Uri>? opened,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        sonarQubeRepositoryProvider.overrideWithValue(repo),
        activeSonarQubeCredentialNotifierProvider.overrideWith(_Credential.new),
        linkLauncherProvider.overrideWithValue((uri) async {
          opened?.add(uri);
          return true;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: SonarQubeIssueScreen(project: _project, issue: issue),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows what is wrong, where, and the facts about it', (
    tester,
  ) async {
    await _pump(tester, _Repo(), _issue());

    expect(
      find.text('Complete the task associated to this TODO comment.'),
      findsOneWidget,
    );
    expect(find.text('Code smell'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('java:S1135'), findsOneWidget);
    expect(find.text('Track uses of TODO tags'), findsOneWidget);
    expect(find.text('src/Foo.java:10'), findsOneWidget);
    expect(find.text('15min to fix'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('dev@example.com'), findsOneWidget);
    expect(find.text('3d ago'), findsOneWidget);
    expect(find.text('todo'), findsOneWidget);
    expect(find.text('convention'), findsOneWidget);
  });

  testWidgets('shows the code around the issue with its line marked', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _Repo(), _issue());

    expect(find.text('CODE'), findsOneWidget);
    expect(find.text('int a = 1;'), findsOneWidget);
    expect(find.text('// TODO fix'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Line 10, the issue: // TODO fix')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'Line 9: int a')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('an issue on a whole project has no code section', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo, _issue(line: null));

    expect(find.text('CODE'), findsNothing);
  });

  testWidgets('without a rule or tags those rows are left out', (tester) async {
    await _pump(tester, _Repo(), _issue(rule: null, tags: const []));

    expect(find.text('Rule'), findsNothing);
    expect(find.text('Tags'), findsNothing);
    expect(find.text('Where'), findsOneWidget);
  });

  testWidgets('code that cannot be loaded says why, and retry works', (
    tester,
  ) async {
    final repo = _Repo()..context = const Err(SonarQubeAccessDeniedFailure());
    await _pump(tester, repo, _issue());

    expect(find.textContaining("isn't allowed to see this"), findsOneWidget);
    // The facts the list already had are still there.
    expect(find.text('src/Foo.java:10'), findsOneWidget);

    repo.context = const Ok(
      SonarQubeIssueContext(
        snippet: [SonarQubeSourceLine(number: 10, code: 'recovered();')],
      ),
    );
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();

    expect(find.text('recovered();'), findsOneWidget);
    expect(repo.contextCalls, 2);
  });

  testWidgets('a rule with no name loaded just shows its key', (tester) async {
    final repo = _Repo()
      ..context = const Ok(
        SonarQubeIssueContext(
          snippet: [SonarQubeSourceLine(number: 10, code: 'x')],
        ),
      );
    await _pump(tester, repo, _issue());

    expect(find.text('java:S1135'), findsOneWidget);
    expect(find.text('Track uses of TODO tags'), findsNothing);
  });

  testWidgets('Open in SonarQube opens this issue in the browser', (
    tester,
  ) async {
    final opened = <Uri>[];
    await _pump(tester, _Repo(), _issue(), opened: opened);

    await tester.tap(find.byTooltip('Open in SonarQube'));
    await tester.pump();

    expect(
      opened.single.toString(),
      'http://192.168.1.53:9000/project/issues'
      '?id=JobTrigger&issues=AX-1&open=AX-1',
    );
  });

  testWidgets('tapping an issue in the list opens its page', (tester) async {
    final repo = _Repo();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SonarQubeIssuesScreen(project: _project),
        ),
        GoRoute(
          path: AppRoutes.sonarqubeIssue,
          builder: (_, state) {
            final (project, issue) =
                state.extra! as (SonarQubeProject, SonarQubeIssue);
            return SonarQubeIssueScreen(project: project, issue: issue);
          },
        ),
      ],
    );
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          sonarQubeRepositoryProvider.overrideWithValue(repo),
          activeSonarQubeCredentialNotifierProvider.overrideWith(
            _Credential.new,
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Complete the task associated to this TODO comment.'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SonarQubeIssueScreen), findsOneWidget);
    expect(find.text('Track uses of TODO tags'), findsOneWidget);
  });
}
