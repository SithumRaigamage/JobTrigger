import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'reduce_transparency_notifier.g.dart';

const _reduceTransparencyKey = 'reduce_transparency';

/// Manual accessibility fallback for the glassmorphism design system
/// (`docs/user-stories/00-design-system-glassmorphism.md`, US-DESIGN-03).
/// Flutter doesn't expose iOS's "Reduce Transparency" signal via
/// `MediaQuery` the way it does reduce-motion/high-contrast/bold-text, so
/// this is a first-party in-app toggle rather than an OS auto-detect.
/// Persisted in `shared_preferences` exactly like [ThemeNotifier]'s theme
/// mode (not sensitive — see CLAUDE.md §7); defaults to `false` (glass
/// effects on).
@riverpod
class ReduceTransparencyNotifier extends _$ReduceTransparencyNotifier {
  @override
  bool build() {
    _loadPersisted();
    return false;
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_reduceTransparencyKey);
    if (stored == null) return;
    state = stored;
  }

  Future<void> setReduceTransparency(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceTransparencyKey, value);
  }
}
