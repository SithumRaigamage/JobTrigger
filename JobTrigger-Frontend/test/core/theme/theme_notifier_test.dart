import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/theme_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to ThemeMode.light with nothing persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeNotifierProvider), ThemeMode.light);
  });

  test('setThemeMode updates state and persists the choice', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeNotifierProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(container.read(themeNotifierProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('rehydrates a previously persisted theme mode on build()', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Without an active listener, this @riverpod provider auto-disposes
    // synchronously after the first read -- before _loadPersisted's async
    // rehydration can land. Keep it alive across that gap, same fix as
    // BuildLogNotifier/BuildStatusPollingNotifier's tests (Phase 5).
    container.listen(themeNotifierProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeNotifierProvider), ThemeMode.light);
  });
}
