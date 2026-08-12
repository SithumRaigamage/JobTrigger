// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
/// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7).

@ProviderFor(ThemeNotifier)
final themeNotifierProvider = ThemeNotifierProvider._();

/// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
/// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7).
final class ThemeNotifierProvider
    extends $NotifierProvider<ThemeNotifier, ThemeMode> {
  /// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
  /// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7).
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

String _$themeNotifierHash() => r'a847f191b86f5f91d02e36caf48455c8fd11efc8';

/// System/Light/Dark, persisted in `shared_preferences` (theme mode isn't
/// sensitive, unlike the JWT/Jenkins credentials — see CLAUDE.md §7).

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
