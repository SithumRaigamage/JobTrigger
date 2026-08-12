import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_notifier.g.dart';

const _themeModeKey = 'theme_mode';

/// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
/// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7). Default
/// is [ThemeMode.light] rather than [ThemeMode.system] — the app's white
/// theme is the intended look regardless of OS appearance; users can still
/// switch to System or Dark from Settings.
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() {
    _loadPersisted();
    return ThemeMode.light;
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    if (stored == null) return;
    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}
