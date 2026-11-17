// P6-07: store screenshots, taken from a simulator in demo mode (sample data
// built into the app, no account, no server). Release 1.0 ships Jenkins,
// SonarQube and GitHub Actions, so the pack has a screen for each tool
// (release-checklist.md, "Release 1.0"). Run once per tool with SHOT_TOOL:
//
//   SCREENSHOT_DIR=../release/store-screenshots/ios-6.9 flutter drive \
//     --driver=test_driver/screenshot_driver.dart \
//     --target=integration_test/store_screenshots_test.dart -d <simulator> \
//     --dart-define-from-file=config/dev.json --dart-define=SHOT_TOOL=jenkins
//   # ... =github, =sonarqube  (see docs/store-submission.md for all commands)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Which tool's screenshots to take. Defaults to Jenkins so the original
  // retake command keeps working; the other two are captured with a define.
  const tool = String.fromEnvironment('SHOT_TOOL', defaultValue: 'jenkins');

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot(name);
  }

  /// Enter demo mode and select [toolCard], landing on that tool's Home tab.
  Future<void> enterDemo(WidgetTester tester, String toolCard) async {
    await app.main();
    await tester.pumpAndSettle();
    // Android needs the surface converted once before any screenshot; on
    // iOS this is a no-op. Converting per shot asserts on the second call.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    final demo = find.byKey(const Key('login_demo_button'));
    if (demo.evaluate().isNotEmpty) {
      await tester.ensureVisible(demo);
      await tester.tap(demo);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    final cont = find.byKey(const Key('tool_continue_button'));
    if (cont.evaluate().isNotEmpty) {
      await tester.tap(find.byKey(Key('tool_card_$toolCard')));
      await tester.pumpAndSettle();
      await tester.tap(cont);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  testWidgets('store screenshots', (tester) async {
    if (tool == 'github') {
      await enterDemo(tester, 'githubActions');
      // GitHub's Home is the repositories list; demo mode has two sample
      // repos (demo-org/app and demo-org/infra).
      await shot(tester, '06-github-repos');
      return;
    }
    if (tool == 'sonarqube') {
      await enterDemo(tester, 'sonarqube');
      // SonarQube's Home is the projects list; demo mode has Demo App
      // (failing gate) and Demo API (passing gate).
      await shot(tester, '07-sonar-projects');
      return;
    }

    // Jenkins (default): the original five-shot flow.
    await enterDemo(tester, 'jenkins');
    await shot(tester, '01-jobs');

    await tester.tap(find.text('demo-app').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await shot(tester, '02-folder');

    await tester.tap(find.text('main').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await shot(tester, '03-job');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('feature-login').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await shot(tester, '04-failing-job');

    await tester.tap(find.text('Log').first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await shot(tester, '05-build-log');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    // No Profile shot: debug builds show a "Send test crash report" row there.
  });
}
