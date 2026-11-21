import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/app_info/app_info_repository.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credentials_repository.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:job_trigger/presentation/features/tool_selection/returning_tool_provider.dart';
import 'package:job_trigger/presentation/features/tool_selection/tool_selection_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// US-TOOL-01 "Returning user skips re-selection" (owner decision
/// 2026-11-21): with at least one saved server, of any tool, tool
/// selection is skipped; from Profile it always shows.
const _jenkins = JenkinsServer(
  id: 'j',
  serverName: 'J',
  jenkinsURL: 'https://j.test',
  username: 'u',
  secret: 'fixture-secret',
);
const _gitHub = GitHubCredential(id: 'g', label: 'G', secret: 'fixture-g');

class _J implements CredentialsRepository {
  _J(this.result);
  final Result<List<JenkinsServer>, AppFailure> result;
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async => result;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _G implements GitHubCredentialsRepository {
  _G(this.result);
  final Result<List<GitHubCredential>, AppFailure> result;
  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async => result;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _S implements SonarQubeCredentialsRepository {
  _S(this.result);
  final Result<List<SonarQubeCredential>, AppFailure> result;
  @override
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll() async =>
      result;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _AppInfo implements AppInfoRepository {
  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async =>
      const Ok(AppInfo(appVersion: '1.0.0', buildNumber: '1'));
}

class _Locking extends ActiveToolNotifier {
  _Locking(this.locked);
  final Set<CiTool> locked;
  @override
  Future<String?> blockedReason(CiTool tool) async =>
      locked.contains(tool) ? 'multiTool' : null;
}

List<Override> _repos({
  List<JenkinsServer> jenkins = const [],
  List<GitHubCredential> gitHub = const [],
  bool unreadable = false,
  Set<CiTool> locked = const {},
}) => [
  credentialsRepositoryProvider.overrideWithValue(
    _J(unreadable ? const Err(NetworkFailure()) : Ok(jenkins)),
  ),
  gitHubCredentialsRepositoryProvider.overrideWithValue(
    _G(unreadable ? const Err(NetworkFailure()) : Ok(gitHub)),
  ),
  sonarQubeCredentialsRepositoryProvider.overrideWithValue(
    _S(unreadable ? const Err(NetworkFailure()) : const Ok([])),
  ),
  activeToolNotifierProvider.overrideWith(() => _Locking(locked)),
];

Future<CiTool?> _pick(List<Override> overrides) async {
  final c = ProviderContainer(overrides: overrides);
  addTearDown(c.dispose);
  return c.read(returningToolProvider.future);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('returningTool', () {
    test('the tool chosen last, when it has a saved server', () async {
      SharedPreferences.setMockInitialValues({'active_tool': 'githubActions'});
      expect(
        await _pick(_repos(jenkins: [_jenkins], gitHub: [_gitHub])),
        CiTool.githubActions,
      );
    });

    test('else the first tool with a saved server', () async {
      expect(await _pick(_repos(gitHub: [_gitHub])), CiTool.githubActions);
      SharedPreferences.setMockInitialValues({'active_tool': 'sonarqube'});
      expect(await _pick(_repos(jenkins: [_jenkins])), CiTool.jenkins);
    });

    test('no saved server anywhere: tool selection shows', () async {
      SharedPreferences.setMockInitialValues({'active_tool': 'jenkins'});
      expect(await _pick(_repos()), isNull);
    });

    test('lists unreadable (offline): the tool chosen last', () async {
      SharedPreferences.setMockInitialValues({'active_tool': 'jenkins'});
      expect(await _pick(_repos(unreadable: true)), CiTool.jenkins);
      SharedPreferences.setMockInitialValues({});
      expect(await _pick(_repos(unreadable: true)), isNull);
    });

    test('a tool the plan locks is never picked', () async {
      SharedPreferences.setMockInitialValues({'active_tool': 'githubActions'});
      expect(
        await _pick(
          _repos(
            jenkins: [_jenkins],
            gitHub: [_gitHub],
            locked: {CiTool.githubActions},
          ),
        ),
        CiTool.jenkins,
      );
    });
  });

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester,
    List<Override> overrides, {
    bool choosing = false,
  }) async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...overrides,
        appInfoRepositoryProvider.overrideWithValue(_AppInfo()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(activeToolNotifierProvider, (_, _) {});
    final router = GoRouter(
      initialLocation: AppRoutes.toolSelection,
      routes: [
        GoRoute(
          path: AppRoutes.toolSelection,
          builder: (_, _) => ToolSelectionScreen(choosing: choosing),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('a returning user goes straight Home with their tool', (
    tester,
  ) async {
    final c = await pumpScreen(tester, _repos(gitHub: [_gitHub]));

    expect(find.text('home'), findsOneWidget);
    expect(c.read(activeToolNotifierProvider), CiTool.githubActions);
  });

  testWidgets('a first-time user sees the picker', (tester) async {
    await pumpScreen(tester, _repos());

    expect(find.text('home'), findsNothing);
    expect(find.text('Continue with Jenkins'), findsOneWidget);
  });

  testWidgets('opened from Profile it always shows the picker', (tester) async {
    await pumpScreen(tester, _repos(jenkins: [_jenkins]), choosing: true);

    expect(find.text('home'), findsNothing);
    expect(find.text('Continue with Jenkins'), findsOneWidget);
  });
}
