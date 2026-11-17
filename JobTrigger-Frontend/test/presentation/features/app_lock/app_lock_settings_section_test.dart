import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/biometric_service.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/app_lock/app_lock_settings_section.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../support/fake_biometric_service.dart';

/// US-JX-21's settings, on the profile since P14-11 (moved from Settings,
/// where these tests used to live).
void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  Future<ProviderContainer> pumpSection(
    WidgetTester tester,
    FakeBiometricService biometrics,
  ) async {
    final container = ProviderContainer(
      overrides: [biometricServiceProvider.overrideWithValue(biometrics)],
    );
    addTearDown(container.dispose);
    container.listen(currentToastProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AppLockSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('turning it on reveals the timeout and the confirm option', (
    tester,
  ) async {
    await pumpSection(tester, FakeBiometricService());
    expect(find.text('Lock after leaving the app'), findsNothing);

    await tester.tap(find.text('App lock'));
    await tester.pumpAndSettle();

    expect(find.text('Lock after leaving the app'), findsOneWidget);
    expect(find.text('After 5 minutes'), findsOneWidget);
    expect(find.text('Confirm before triggering'), findsOneWidget);
  });

  testWidgets('without device security it explains why it stays off', (
    tester,
  ) async {
    final container = await pumpSection(
      tester,
      FakeBiometricService(AuthOutcome.unavailable),
    );

    await tester.tap(find.text('App lock'));
    await tester.pump();

    expect(
      container.read(currentToastProvider)?.title,
      "Can't turn on app lock",
    );
    expect(find.text('Lock after leaving the app'), findsNothing);
    await tester.pump(const Duration(seconds: 4)); // Toast auto-dismiss.
  });
}
