import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/onboarding/whats_new.dart';
import 'package:job_trigger/presentation/features/whats_new/whats_new_gate.dart';
import 'package:job_trigger/presentation/features/whats_new/whats_new_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

PackageInfo _info(String version) => PackageInfo(
  appName: 'JobTrigger',
  packageName: 'app',
  version: version,
  buildNumber: '7',
);

Future<void> _pumpGate(WidgetTester tester, String version) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        whatsNewPackageInfoProvider.overrideWith((ref) async => _info(version)),
      ],
      child: const MaterialApp(
        home: WhatsNewGate(child: Scaffold(body: Text('home'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the sheet lists the release notes', (tester) async {
    final release = whatsNewFor('1.0.0')!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // US-PROF-05: the body has a scrolling area, so it needs a bounded
          // height here, just as it does in the modal sheet.
          body: SizedBox(height: 600, child: WhatsNewSheet(release: release)),
        ),
      ),
    );

    expect(find.text("What's new"), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.text('Version 1.0'), findsOneWidget);
    for (final item in release.items) {
      expect(find.text(item), findsOneWidget);
    }
  });

  testWidgets('long notes scroll while the action stays on screen', (
    tester,
  ) async {
    final release = WhatsNewRelease(
      version: '1.0',
      items: [for (var i = 1; i <= 40; i++) 'Release note $i'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 360, child: WhatsNewSheet(release: release)),
        ),
      ),
    );

    expect(tester.getRect(find.text('Got it')).bottom, lessThanOrEqualTo(360));
    await tester.scrollUntilVisible(find.text('Release note 40'), 100);
    expect(find.text('Release note 40'), findsOneWidget);
  });

  testWidgets('the modal sheet leaves a strip of the app visible', (
    tester,
  ) async {
    await _pumpGate(tester, '1.0.0');

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            (w.constraints.maxHeight - screenHeight * 0.85).abs() < 1,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the gate shows the notes once per version', (tester) async {
    await _pumpGate(tester, '1.0.0');

    expect(find.text("What's new"), findsOneWidget);
    // No ensureVisible: the primary action must already be on screen.
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text("What's new"), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(whatsNewSeenVersionKey), '1.0.0');
  });

  testWidgets('the close button dismisses and records the version', (
    tester,
  ) async {
    await _pumpGate(tester, '1.0.0');

    expect(find.text("What's new"), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text("What's new"), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(whatsNewSeenVersionKey), '1.0.0');
  });

  testWidgets('the gate stays quiet once this version has been seen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({whatsNewSeenVersionKey: '1.0.0'});

    await _pumpGate(tester, '1.0.0');

    expect(find.text("What's new"), findsNothing);
  });

  testWidgets('the gate has nothing to show for a version without notes', (
    tester,
  ) async {
    await _pumpGate(tester, '2.0.0');

    expect(find.text("What's new"), findsNothing);
  });
}
