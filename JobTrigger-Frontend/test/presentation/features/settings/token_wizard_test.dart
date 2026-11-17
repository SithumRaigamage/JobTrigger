import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/presentation/features/settings/github_credential_edit_bottom_sheet.dart';
import 'package:job_trigger/presentation/features/settings/server_edit_bottom_sheet.dart';
import 'package:job_trigger/presentation/features/settings/sonarqube_credential_edit_bottom_sheet.dart';
import 'package:job_trigger/presentation/features/settings/token_wizard_sheet.dart';

/// Records every link the user asks to open.
class _Links {
  final opened = <Uri>[];

  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

Future<_Links> _pump(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final links = _Links();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [linkLauncherProvider.overrideWithValue(links.open)],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return links;
}

Future<void> _openWizard(WidgetTester tester) async {
  await tester.tap(find.text('How do I get a token?'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Jenkins wizard names the right steps and link', (
    tester,
  ) async {
    final links = await _pump(tester, const ServerEditBottomSheet());
    await tester.enterText(
      find.byType(TextField).at(1), // Server URL
      'https://ci.test/jenkins/',
    );
    await tester.pump();
    await _openWizard(tester);

    expect(find.text('Create a Jenkins API token'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TokenWizardSheet),
        matching: find.textContaining('API tokens'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Open Jenkins'));
    await tester.pumpAndSettle();
    expect(
      links.opened.single.toString(),
      'https://ci.test/jenkins/me/configure',
    );
  });

  testWidgets('the GitHub wizard opens the scoped token page', (tester) async {
    final links = await _pump(tester, const GitHubCredentialEditBottomSheet());
    await _openWizard(tester);

    expect(find.text('Create a GitHub token'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TokenWizardSheet),
        matching: find.textContaining('repo and workflow scopes'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Actions read and write'), findsOneWidget);

    await tester.tap(find.text('Open GitHub'));
    await tester.pumpAndSettle();
    expect(links.opened.single.host, 'github.com');
    expect(links.opened.single.queryParameters['scopes'], 'repo,workflow');
  });

  testWidgets('the SonarQube wizard follows the instance URL', (tester) async {
    final links = await _pump(
      tester,
      const SonarQubeCredentialEditBottomSheet(),
    );
    await tester.enterText(
      find.byType(TextField).at(1), // Instance URL
      'https://sonar.example.com',
    );
    await tester.pump();
    await _openWizard(tester);

    expect(find.text('Create a SonarQube token'), findsOneWidget);

    await tester.tap(find.text('Open SonarQube'));
    await tester.pumpAndSettle();
    expect(
      links.opened.single.toString(),
      'https://sonar.example.com/user/account/security',
    );
  });

  testWidgets('every credential sheet offers the token wizard', (tester) async {
    for (final body in const [
      ServerEditBottomSheet(),
      GitHubCredentialEditBottomSheet(),
      SonarQubeCredentialEditBottomSheet(),
    ]) {
      await _pump(tester, body);
      expect(
        find.text('How do I get a token?'),
        findsOneWidget,
        reason: '${body.runtimeType} needs the wizard button',
      );
    }
  });
}
