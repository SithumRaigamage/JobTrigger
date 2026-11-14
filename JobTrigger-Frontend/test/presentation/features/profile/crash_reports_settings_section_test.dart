import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error_reporting/crash_reporting.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/features/profile/crash_reports_settings_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReporting implements CrashReporting {
  final changes = <bool>[];
  var tests = 0;

  @override
  bool get enabled => true;

  @override
  bool get started => false;

  @override
  Future<void> setEnabled(bool value, config) async => changes.add(value);

  @override
  Future<void> sendTestReport() async => tests++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late _FakeReporting reporting;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    reporting = _FakeReporting();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [crashReportingProvider.overrideWithValue(reporting)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: CrashReportsSettingsSection()),
      ),
    ),
  );

  testWidgets('the switch is on by default and can be turned off', (
    tester,
  ) async {
    await pump(tester);
    final tile = find.widgetWithText(SwitchListTile, 'Send crash reports');
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(reporting.changes, [false]);
  });

  testWidgets('a test report can be sent from a non-release build', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Send test crash report'));
    await tester.pump();
    expect(reporting.tests, 1);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('the test action is disabled while reports are off', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Send crash reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send test crash report'));
    await tester.pump();
    expect(reporting.tests, 0);
  });
}
