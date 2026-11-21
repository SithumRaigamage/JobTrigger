import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/jenkins/server_status.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/home/server_status_provider.dart';
import 'package:job_trigger/presentation/features/settings/settings_screen.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// US-CRED-01 / US-CRED-04: the Jenkins server list in Settings.
const _prod = JenkinsServer(
  id: 'prod',
  serverName: 'Production',
  jenkinsURL: 'https://prod.example.com',
  username: 'admin',
  secret: 'super-secret-password',
  isDefault: true,
);
const _staging = JenkinsServer(
  id: 'staging',
  serverName: 'Staging',
  jenkinsURL: 'https://staging.example.com',
  username: 'ci',
  secret: 'staging-fixture-secret',
);

class _Repo implements CredentialsRepository {
  _Repo({this.fetch, this.deleteResult = const Ok(null)});

  final Result<List<JenkinsServer>, AppFailure>? fetch;
  final Result<void, AppFailure> deleteResult;
  final deleted = <String>[];
  bool _gone = false;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      fetch ?? Ok([if (!_gone) _prod, _staging]);

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    deleted.add(id);
    if (deleteResult is Ok) _gone = id == 'prod';
    return deleteResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoGitHub extends GitHubCredentialsNotifier {
  @override
  Future<List<GitHubCredential>> build() async => const [];
}

class _NoSonar extends SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async => const [];
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Repo repo, {
  ServerStatus? status,
}) async {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      if (status != null)
        serverStatusProvider.overrideWith((ref) async => status),
      credentialsRepositoryProvider.overrideWithValue(repo),
      gitHubCredentialsNotifierProvider.overrideWith(_NoGitHub.new),
      sonarQubeCredentialsNotifierProvider.overrideWith(_NoSonar.new),
    ],
  );
  addTearDown(container.dispose);
  container.listen(currentToastProvider, (_, _) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _swipeAway(WidgetTester tester, String name) async {
  await tester.drag(find.text(name), const Offset(-600, 0));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets('lists servers, marks the active one, never shows a secret', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _Repo());

    expect(find.text('Production'), findsOneWidget);
    expect(find.text('Staging'), findsOneWidget);
    expect(find.text('https://prod.example.com'), findsOneWidget);
    expect(find.textContaining('super-secret-password'), findsNothing);
    expect(find.textContaining('staging-fixture-secret'), findsNothing);

    SemanticsNode row(String name) => tester.getSemantics(
      find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first,
    );
    expect(row('Production').flagsCollection.isSelected, Tristate.isTrue);
    expect(row('Staging').flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  // US-JX-18 "Info" / "Outdated version" and US-JX-22 "Existing servers".
  testWidgets('the active server shows its Jenkins version, old ones with a '
      'hint; a password-looking secret is noted', (tester) async {
    await _pump(tester, _Repo(), status: const ServerStatus(version: '2.100'));

    expect(find.textContaining('Jenkins 2.100'), findsOneWidget);
    expect(find.textContaining('consider upgrading'), findsOneWidget);
    expect(find.text('Uses a password'), findsWidgets);
  });

  testWidgets('a current Jenkins shows no upgrade hint', (tester) async {
    await _pump(tester, _Repo(), status: const ServerStatus(version: '2.999'));

    expect(find.textContaining('Jenkins 2.999'), findsOneWidget);
    expect(find.textContaining('consider upgrading'), findsNothing);
  });

  testWidgets('a failed load shows the connection error with Retry', (
    tester,
  ) async {
    await _pump(tester, _Repo(fetch: const Err(NetworkFailure())));

    expect(find.text('Retry Connection'), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });

  testWidgets('deleting asks first; Cancel sends nothing', (tester) async {
    final repo = _Repo();
    await _pump(tester, repo);

    await _swipeAway(tester, 'Staging');
    expect(find.text('Delete server?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.deleted, isEmpty);
    expect(find.text('Staging'), findsOneWidget);
  });

  testWidgets('confirming deletes the server', (tester) async {
    final repo = _Repo();
    await _pump(tester, repo);

    await _swipeAway(tester, 'Production');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleted, ['prod']);
    expect(find.text('Production'), findsNothing);
  });

  failedSaveTests();

  testWidgets('a failed delete keeps the server and says why', (tester) async {
    final repo = _Repo(deleteResult: const Err(NetworkFailure()));
    final container = await _pump(tester, repo);

    await _swipeAway(tester, 'Staging');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleted, ['staging']);
    expect(container.read(currentToastProvider)?.title, 'Delete Failed');
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Staging'), findsOneWidget);
  });
}

// US-CRED-02 "Save failure" / US-CRED-03 "Edit failure": the sheet stays
// open with what was typed, and the list still shows the saved values.
class _FailingSaves extends _Repo {
  _FailingSaves() : super();

  int saves = 0;

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    saves++;
    return const Err(NetworkFailure());
  }
}

void failedSaveTests() {
  testWidgets('a failed edit keeps the typed values and the saved list', (
    tester,
  ) async {
    final repo = _FailingSaves();
    final container = await _pump(tester, repo);

    await tester.tap(find.byTooltip('Edit Production'));
    await tester.pumpAndSettle();
    expect(find.text('Edit server'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Production'),
      'Production EU',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.saves, 1);
    expect(container.read(currentToastProvider)?.title, 'Save Failed');
    expect(find.text('Edit server'), findsOneWidget);
    expect(find.text('Production EU'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    Navigator.of(tester.element(find.text('Edit server'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Production'), findsOneWidget);
    expect(find.text('Production EU'), findsNothing);
  });
}
