import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/biometric_service.dart';
import 'package:job_trigger/presentation/features/app_lock/app_lock_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_biometric_service.dart';

void main() {
  late FakeBiometricService biometrics;

  Future<void> pumpGate(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [biometricServiceProvider.overrideWithValue(biometrics)],
        child: MaterialApp(
          builder: (context, child) => AppLockGate(child: child!),
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Secret job'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() => biometrics = FakeBiometricService());

  testWidgets('with the lock off the app is usable straight away', (
    tester,
  ) async {
    await pumpGate(tester, {});
    expect(find.text('JobTrigger is locked'), findsNothing);
    expect(find.text('Secret job'), findsOneWidget);
  });

  testWidgets('a locked app hides its content and unlocks on success '
      '(US-JX-21)', (tester) async {
    final semantics = tester.ensureSemantics();
    biometrics.outcome = AuthOutcome.failed;
    await pumpGate(tester, {'app_lock_enabled': true});

    expect(find.text('JobTrigger is locked'), findsOneWidget);
    // Unreachable by screen readers while covered.
    expect(find.bySemanticsLabel('Secret job'), findsNothing);

    biometrics.outcome = AuthOutcome.success;
    await tester.tap(find.text('Unlock'));
    await tester.pump();

    expect(find.text('JobTrigger is locked'), findsNothing);
    expect(find.bySemanticsLabel('Secret job'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the app switcher sees the privacy screen, not the content', (
    tester,
  ) async {
    await pumpGate(tester, {'app_lock_enabled': true}); // Auto-unlocks.
    expect(find.text('JobTrigger is locked'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('JobTrigger is locked'), findsOneWidget);
    expect(find.text('Unlock'), findsNothing); // Just a cover.

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('JobTrigger is locked'), findsNothing);
  });
}
