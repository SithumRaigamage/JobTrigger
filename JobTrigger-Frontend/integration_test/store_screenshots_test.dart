// P6-07: store screenshots, taken from a simulator in demo mode (sample data
// built into the app, no account, no server). Release 1.0 is Jenkins only, so
// only Jenkins screens are captured (release-checklist.md, "Release 1.0").
//
//   SCREENSHOT_DIR=release/store-screenshots/ios-6.9 flutter drive \
//     --driver=test_driver/screenshot_driver.dart \
//     --target=integration_test/store_screenshots_test.dart -d <simulator> \
//     --dart-define-from-file=config/dev.json
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('store screenshots', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    final demo = find.byKey(const Key('login_demo_button'));
    if (demo.evaluate().isNotEmpty) {
      await tester.ensureVisible(demo);
      await tester.tap(demo);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    final cont = find.byKey(const Key('tool_continue_button'));
    if (cont.evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('tool_card_jenkins')));
      await tester.pumpAndSettle();
      await tester.tap(cont);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
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
