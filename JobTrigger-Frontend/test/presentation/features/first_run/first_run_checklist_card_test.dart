import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_watch.dart';
import 'package:job_trigger/presentation/features/first_run/first_run_checklist_card.dart';
import 'package:job_trigger/presentation/features/first_run/first_run_notifier.dart';
import 'package:job_trigger/presentation/features/notifications/build_watch_notifier.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_watch_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _server = JenkinsServer(
  id: 's1',
  serverName: 'CI',
  jenkinsURL: 'https://ci.test',
  username: 'sam',
  secret: 'secret',
);

const _watch = BuildWatch(
  serverId: 's1',
  jobUrl: 'https://ci.test/job/api/',
  jobLabel: 'api',
);

class _Servers extends CredentialsNotifier {
  _Servers(this.connected);

  final bool connected;

  @override
  Future<List<JenkinsServer>> build() async =>
      connected ? const [_server] : const [];
}

class _GitHub extends GitHubCredentialsNotifier {
  _GitHub(this.connected);

  final bool connected;

  @override
  Future<List<GitHubCredential>> build() async => connected
      ? const [GitHubCredential(id: 'g', label: 'Work', secret: 't')]
      : const [];
}

class _Sonar extends SonarQubeCredentialsNotifier {
  _Sonar(this.connected);

  final bool connected;

  @override
  Future<List<SonarQubeCredential>> build() async => connected
      ? const [
          SonarQubeCredential(
            id: 'q',
            label: 'Work',
            baseUrl: 'https://sonar.test',
            secret: 't',
          ),
        ]
      : const [];
}

Future<void> _pump(
  WidgetTester tester, {
  bool connected = false,
  bool triggered = false,
  bool alerts = false,
  bool demo = false,
  bool dismissed = false,
}) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    firstRunTriggeredKey: triggered,
    firstRunDismissedKey: dismissed,
  });

  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        credentialsNotifierProvider.overrideWith(() => _Servers(connected)),
        gitHubCredentialsNotifierProvider.overrideWith(
          () => _GitHub(connected),
        ),
        sonarQubeCredentialsNotifierProvider.overrideWith(
          () => _Sonar(connected),
        ),
        buildWatchNotifierProvider.overrideWithValue(
          alerts ? const [_watch] : const <BuildWatch>[],
        ),
        sonarQubeWatchNotifierProvider.overrideWithValue(
          const <SonarQubeProjectWatch>[],
        ),
        demoModeInitialProvider.overrideWithValue(demo),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SingleChildScrollView(child: FirstRunChecklistCard()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the three steps and how many are done', (tester) async {
    await _pump(tester);

    expect(find.text('Get started'), findsOneWidget);
    expect(
      find.text('0 of 3 done — three steps to your first build.'),
      findsOneWidget,
    );
    expect(find.text('Connect a server'), findsOneWidget);
    expect(find.text('Trigger a build'), findsOneWidget);
    expect(find.text('Turn on alerts'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('a saved credential completes the first step', (tester) async {
    await _pump(tester, connected: true);

    expect(
      find.text('1 of 3 done — three steps to your first build.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('a stored trigger completes the second step', (tester) async {
    await _pump(tester, connected: true, triggered: true);

    expect(
      find.text('2 of 3 done — three steps to your first build.'),
      findsOneWidget,
    );
  });

  testWidgets('retires once all three steps are done', (tester) async {
    await _pump(tester, connected: true, triggered: true, alerts: true);

    expect(find.byKey(firstRunChecklistKey), findsNothing);
  });

  testWidgets('is hidden in demo mode', (tester) async {
    await _pump(tester, demo: true);

    expect(find.byKey(firstRunChecklistKey), findsNothing);
  });

  testWidgets('stays hidden once dismissed', (tester) async {
    await _pump(tester, dismissed: true);

    expect(find.byKey(firstRunChecklistKey), findsNothing);
  });

  testWidgets('the dismiss button hides it and remembers', (tester) async {
    await _pump(tester);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.byKey(firstRunChecklistKey), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(firstRunDismissedKey), isTrue);
  });
}
