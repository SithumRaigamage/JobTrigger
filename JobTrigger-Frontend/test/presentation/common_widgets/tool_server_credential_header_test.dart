import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/presentation/common_widgets/tool_server_credential_header.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

import '../../support/plan_gates.dart';

void main() {
  final dev = sonarQubeCredentialNamed('Dev');
  final prod = sonarQubeCredentialNamed('Prod');

  SonarQubeCredentialHeader sonarHeader({
    SonarQubeCredential? credential,
    ValueChanged<SonarQubeCredential>? onSwitch,
    List<Widget> actions = const [],
  }) {
    return SonarQubeCredentialHeader(
      credential: credential ?? dev,
      onSwitch: onSwitch ?? (_) {},
      actions: actions,
    );
  }

  Future<void> pumpHeader(
    WidgetTester tester,
    Widget header, {
    List<JenkinsServer> jenkins = const [],
    List<GitHubCredential> github = const [],
    List<SonarQubeCredential> sonarqube = const [],
    GoRouter? router,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: savedCredentials(
          jenkins: jenkins,
          github: github,
          sonarqube: sonarqube,
        ),
        child: router == null
            ? MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
                home: Scaffold(body: Center(child: header)),
              )
            : MaterialApp.router(routerConfig: router),
      ),
    );
    // The saved lists are async providers; let their first frame land.
    await tester.pumpAndSettle();
  }

  testWidgets('shows the active credential and opens the saved list', (
    tester,
  ) async {
    await pumpHeader(tester, sonarHeader(), sonarqube: [dev, prod]);

    expect(find.text('Dev'), findsOneWidget);
    expect(
      find.bySemanticsLabel('SonarQube Dev. Switch credential'),
      findsOneWidget,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Prod'), findsOneWidget);
    expect(find.text('https://Prod.test'), findsOneWidget);
    // Exactly one check, on the active entry.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('switching calls onSwitch with the chosen credential', (
    tester,
  ) async {
    SonarQubeCredential? chosen;
    await pumpHeader(
      tester,
      sonarHeader(onSwitch: (value) => chosen = value),
      sonarqube: [dev, prod],
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prod'));
    await tester.pumpAndSettle();

    expect(chosen, prod);
  });

  testWidgets('long credential fits a 320pt layout at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = sonarQubeCredentialNamed(
      'Production SonarQube server for the payments team',
    );

    await pumpHeader(
      tester,
      sonarHeader(credential: long),
      sonarqube: [long],
      textScale: 2,
    );

    expect(
      find.bySemanticsLabel(RegExp('Production SonarQube')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the active entry does not call onSwitch', (
    tester,
  ) async {
    var calls = 0;
    await pumpHeader(
      tester,
      sonarHeader(onSwitch: (_) => calls++),
      sonarqube: [dev, prod],
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dev').last);
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('Manage credentials opens Settings', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: sonarHeader()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const Scaffold(body: Text('Settings stub')),
        ),
      ],
    );

    await pumpHeader(tester, sonarHeader(), sonarqube: [dev], router: router);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage credentials…'));
    await tester.pumpAndSettle();

    expect(find.text('Settings stub'), findsOneWidget);
  });

  testWidgets('keeps the screen actions on the same line', (tester) async {
    await pumpHeader(
      tester,
      sonarHeader(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {},
          ),
        ],
      ),
      sonarqube: [dev],
    );

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Dev'), findsOneWidget);
  });

  testWidgets('a long server name ellipsizes instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpHeader(
      tester,
      sonarHeader(
        credential: sonarQubeCredentialNamed(
          'A very long SonarQube credential label that cannot fit',
        ),
      ),
      sonarqube: [dev],
    );

    expect(tester.takeException(), isNull);
    final label = tester.widget<Text>(
      find.text('A very long SonarQube credential label that cannot fit'),
    );
    expect(label.overflow, TextOverflow.ellipsis);
  });

  testWidgets('Jenkins header switches servers and shows the URL', (
    tester,
  ) async {
    final local = jenkinsServerNamed('local');
    final remote = jenkinsServerNamed('remote');
    JenkinsServer? chosen;

    await pumpHeader(
      tester,
      JenkinsServerHeader(server: local, onSwitch: (value) => chosen = value),
      jenkins: [local, remote],
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('https://remote.test'), findsOneWidget);
    expect(find.text('Manage servers…'), findsOneWidget);

    await tester.tap(find.text('remote'));
    await tester.pumpAndSettle();
    expect(chosen, remote);
  });

  testWidgets('GitHub header switches credentials', (tester) async {
    final one = gitHubCredentialNamed('work');
    final two = gitHubCredentialNamed('personal');
    GitHubCredential? chosen;

    await pumpHeader(
      tester,
      GitHubCredentialHeader(
        credential: one,
        onSwitch: (value) => chosen = value,
      ),
      github: [one, two],
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('personal'));
    await tester.pumpAndSettle();

    expect(chosen, two);
  });
}
