// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reduce_transparency_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manual accessibility fallback for the glassmorphism design system
/// (`docs/user-stories/00-design-system-glassmorphism.md`, US-DESIGN-03).
/// Flutter doesn't expose iOS's "Reduce Transparency" signal via
/// `MediaQuery` the way it does reduce-motion/high-contrast/bold-text, so
/// this is a first-party in-app toggle rather than an OS auto-detect.
/// Persisted in `shared_preferences` exactly like [ThemeNotifier]'s theme
/// mode (not sensitive — see CLAUDE.md §7); defaults to `false` (glass
/// effects on).

@ProviderFor(ReduceTransparencyNotifier)
final reduceTransparencyNotifierProvider =
    ReduceTransparencyNotifierProvider._();

/// Manual accessibility fallback for the glassmorphism design system
/// (`docs/user-stories/00-design-system-glassmorphism.md`, US-DESIGN-03).
/// Flutter doesn't expose iOS's "Reduce Transparency" signal via
/// `MediaQuery` the way it does reduce-motion/high-contrast/bold-text, so
/// this is a first-party in-app toggle rather than an OS auto-detect.
/// Persisted in `shared_preferences` exactly like [ThemeNotifier]'s theme
/// mode (not sensitive — see CLAUDE.md §7); defaults to `false` (glass
/// effects on).
final class ReduceTransparencyNotifierProvider
    extends $NotifierProvider<ReduceTransparencyNotifier, bool> {
  /// Manual accessibility fallback for the glassmorphism design system
  /// (`docs/user-stories/00-design-system-glassmorphism.md`, US-DESIGN-03).
  /// Flutter doesn't expose iOS's "Reduce Transparency" signal via
  /// `MediaQuery` the way it does reduce-motion/high-contrast/bold-text, so
  /// this is a first-party in-app toggle rather than an OS auto-detect.
  /// Persisted in `shared_preferences` exactly like [ThemeNotifier]'s theme
  /// mode (not sensitive — see CLAUDE.md §7); defaults to `false` (glass
  /// effects on).
  ReduceTransparencyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reduceTransparencyNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reduceTransparencyNotifierHash();

  @$internal
  @override
  ReduceTransparencyNotifier create() => ReduceTransparencyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$reduceTransparencyNotifierHash() =>
    r'3f645a0e7bb0bf7a169c4e408be3d9615691519e';

/// Manual accessibility fallback for the glassmorphism design system
/// (`docs/user-stories/00-design-system-glassmorphism.md`, US-DESIGN-03).
/// Flutter doesn't expose iOS's "Reduce Transparency" signal via
/// `MediaQuery` the way it does reduce-motion/high-contrast/bold-text, so
/// this is a first-party in-app toggle rather than an OS auto-detect.
/// Persisted in `shared_preferences` exactly like [ThemeNotifier]'s theme
/// mode (not sensitive — see CLAUDE.md §7); defaults to `false` (glass
/// effects on).

abstract class _$ReduceTransparencyNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
