import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/biometric_service.dart';
import 'package:job_trigger/presentation/features/app_lock/app_lock_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_biometric_service.dart';

void main() {
  late FakeBiometricService biometrics;
  late DateTime clock;

  setUp(() {
    biometrics = FakeBiometricService();
    clock = DateTime(2026, 9, 30, 12);
  });

  Future<ProviderContainer> container([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = ProviderContainer(
      overrides: [biometricServiceProvider.overrideWithValue(biometrics)],
    );
    addTearDown(c.dispose);
    c.read(appLockNotifierProvider.notifier).now = () => clock;
    await Future<void>.delayed(Duration.zero); // Settings load.
    await Future<void>.delayed(Duration.zero); // Auto-prompt, if any.
    return c;
  }

  AppLockNotifier notifierOf(ProviderContainer c) =>
      c.read(appLockNotifierProvider.notifier);

  test('off by default: loads unlocked and never prompts', () async {
    final c = await container();
    final state = c.read(appLockNotifierProvider);
    expect(state.loaded, isTrue);
    expect(state.locked, isFalse);
    expect(biometrics.reasons, isEmpty);
    expect(await notifierOf(c).confirmSensitive('x'), isTrue);
  });

  test('when on, a cold start locks and prompts straight away', () async {
    biometrics.outcome = AuthOutcome.failed;
    final c = await container({'app_lock_enabled': true});
    expect(c.read(appLockNotifierProvider).locked, isTrue);
    expect(biometrics.reasons, ['Unlock JobTrigger']);

    biometrics.outcome = AuthOutcome.success;
    await notifierOf(c).unlock();
    expect(c.read(appLockNotifierProvider).locked, isFalse);
  });

  test('locks on resume only after the timeout', () async {
    final c = await container({
      'app_lock_enabled': true,
      'app_lock_timeout_seconds': 60,
    });
    expect(c.read(appLockNotifierProvider).locked, isFalse); // Unlocked.
    final notifier = notifierOf(c);

    notifier.onLifecycleChanged(AppLifecycleState.inactive);
    expect(c.read(appLockNotifierProvider).obscured, isTrue);
    notifier.onLifecycleChanged(AppLifecycleState.paused);
    clock = clock.add(const Duration(seconds: 30));
    notifier.onLifecycleChanged(AppLifecycleState.resumed);
    expect(c.read(appLockNotifierProvider).locked, isFalse);
    expect(c.read(appLockNotifierProvider).obscured, isFalse);

    biometrics.outcome = AuthOutcome.failed;
    notifier.onLifecycleChanged(AppLifecycleState.paused);
    clock = clock.add(const Duration(minutes: 2));
    notifier.onLifecycleChanged(AppLifecycleState.resumed);
    expect(c.read(appLockNotifierProvider).locked, isTrue);
  });

  test("the OS prompt's own lifecycle changes don't re-lock", () async {
    final c = await container({
      'app_lock_enabled': true,
      'app_lock_timeout_seconds': 0,
    });
    // The cold-start prompt succeeded. A resume without a real trip away
    // (as after the Face ID sheet) keeps it unlocked.
    notifierOf(c).onLifecycleChanged(AppLifecycleState.resumed);
    expect(c.read(appLockNotifierProvider).locked, isFalse);
  });

  test('enabling authenticates first and persists', () async {
    final c = await container();
    expect(await notifierOf(c).setEnabled(true), LockChange.changed);
    expect(biometrics.reasons, ['Turn on app lock']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('app_lock_enabled'), isTrue);
  });

  test("can't be enabled without device security", () async {
    biometrics.outcome = AuthOutcome.unavailable;
    final c = await container();
    expect(await notifierOf(c).setEnabled(true), LockChange.noDeviceSecurity);
    expect(c.read(appLockNotifierProvider).settings.enabled, isFalse);
  });

  test('a cancelled confirmation leaves it off', () async {
    biometrics.outcome = AuthOutcome.failed;
    final c = await container();
    expect(await notifierOf(c).setEnabled(true), LockChange.cancelled);
    expect(c.read(appLockNotifierProvider).settings.enabled, isFalse);
  });

  test('a removed device passcode turns the lock off instead of '
      'locking the user out', () async {
    biometrics.outcome = AuthOutcome.unavailable;
    final c = await container({'app_lock_enabled': true});
    final state = c.read(appLockNotifierProvider);
    expect(state.locked, isFalse);
    expect(state.settings.enabled, isFalse);
  });

  test('sensitive actions re-prompt only when asked to', () async {
    final c = await container({'app_lock_enabled': true});
    final notifier = notifierOf(c);
    biometrics.reasons.clear();
    expect(await notifier.confirmSensitive('Confirm to trigger api'), isTrue);
    expect(biometrics.reasons, isEmpty);

    await notifier.setRequireForSensitive(true);
    biometrics.outcome = AuthOutcome.failed;
    expect(await notifier.confirmSensitive('Confirm to trigger api'), isFalse);
    expect(biometrics.reasons, ['Confirm to trigger api']);
  });

  test('an unoffered stored timeout falls back to 5 minutes', () async {
    final c = await container({'app_lock_timeout_seconds': 42});
    expect(
      c.read(appLockNotifierProvider).settings.timeout,
      const Duration(minutes: 5),
    );
  });
}
