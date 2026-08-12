// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
/// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7). Default
/// is [ThemeMode.light] rather than [ThemeMode.system] — the app's white
/// theme is the intended look regardless of OS appearance; users can still
/// switch to System or Dark from Settings.

@ProviderFor(ThemeNotifier)
final themeNotifierProvider = ThemeNotifierProvider._();

/// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
/// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7). Default
/// is [ThemeMode.light] rather than [ThemeMode.system] — the app's white
/// theme is the intended look regardless of OS appearance; users can still
/// switch to System or Dark from Settings.
final class ThemeNotifierProvider
    extends $NotifierProvider<ThemeNotifier, ThemeMode> {
  /// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
  /// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7). Default
  /// is [ThemeMode.light] rather than [ThemeMode.system] — the app's white
  /// theme is the intended look regardless of OS appearance; users can still
  /// switch to System or Dark from Settings.
  ThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeNotifierHash() => r'2b8c4311c6d820d7a138d7b5dcc6cd4c0e03673c';

/// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
/// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7). Default
/// is [ThemeMode.light] rather than [ThemeMode.system] — the app's white
/// theme is the intended look regardless of OS appearance; users can still
/// switch to System or Dark from Settings.

abstract class _$ThemeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
