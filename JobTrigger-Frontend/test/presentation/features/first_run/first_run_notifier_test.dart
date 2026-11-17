import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/first_run/first_run_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('starts with nothing done', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(firstRunNotifierProvider), (
      triggered: false,
      dismissed: false,
    ));
  });

  test('loads stored flags', () async {
    SharedPreferences.setMockInitialValues({
      firstRunTriggeredKey: true,
      firstRunDismissedKey: true,
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);
    for (var i = 0; i < 20; i++) {
      if (c.read(firstRunNotifierProvider).triggered) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(c.read(firstRunNotifierProvider), (
      triggered: true,
      dismissed: true,
    ));
  });

  test('markTriggered persists for the next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(firstRunNotifierProvider.notifier).markTriggered();
    expect(c.read(firstRunNotifierProvider).triggered, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(firstRunTriggeredKey), isTrue);
  });

  test('dismiss persists and leaves the trigger flag alone', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(firstRunNotifierProvider.notifier).dismiss();
    expect(c.read(firstRunNotifierProvider).dismissed, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(firstRunDismissedKey), isTrue);
    expect(prefs.getBool(firstRunTriggeredKey), isNull);
  });
}
