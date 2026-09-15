// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_tool_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which CI/CD tool's brand color tints `AppTheme`'s `primary`/`onPrimary`
/// (see `core/theme/app_theme.dart` and `main.dart`). `null` means "no tool
/// selected yet" — `Login`/`Signup`/`ToolSelectionScreen` render with the
/// original blue-and-white theme in that state; the app only turns
/// tool-colored once a card is actually tapped on `ToolSelectionScreen`.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore — and
/// persisting it previously meant a stale "jenkins" from an earlier session
/// made the pre-selection screens start red instead of blue, which is
/// exactly the bug this avoids.

@ProviderFor(ActiveToolNotifier)
final activeToolNotifierProvider = ActiveToolNotifierProvider._();

/// Which CI/CD tool's brand color tints `AppTheme`'s `primary`/`onPrimary`
/// (see `core/theme/app_theme.dart` and `main.dart`). `null` means "no tool
/// selected yet" — `Login`/`Signup`/`ToolSelectionScreen` render with the
/// original blue-and-white theme in that state; the app only turns
/// tool-colored once a card is actually tapped on `ToolSelectionScreen`.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore — and
/// persisting it previously meant a stale "jenkins" from an earlier session
/// made the pre-selection screens start red instead of blue, which is
/// exactly the bug this avoids.
final class ActiveToolNotifierProvider
    extends $NotifierProvider<ActiveToolNotifier, CiTool?> {
  /// Which CI/CD tool's brand color tints `AppTheme`'s `primary`/`onPrimary`
  /// (see `core/theme/app_theme.dart` and `main.dart`). `null` means "no tool
  /// selected yet" — `Login`/`Signup`/`ToolSelectionScreen` render with the
  /// original blue-and-white theme in that state; the app only turns
  /// tool-colored once a card is actually tapped on `ToolSelectionScreen`.
  ///
  /// Deliberately in-memory only, *not* persisted: an authenticated user is
  /// always routed back through `ToolSelectionScreen` after a cold launch
  /// (see `app_router.dart`'s redirect), so there's nothing to restore — and
  /// persisting it previously meant a stale "jenkins" from an earlier session
  /// made the pre-selection screens start red instead of blue, which is
  /// exactly the bug this avoids.
  ActiveToolNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeToolNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeToolNotifierHash();

  @$internal
  @override
  ActiveToolNotifier create() => ActiveToolNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CiTool? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CiTool?>(value),
    );
  }
}

String _$activeToolNotifierHash() =>
    r'd5d59b38a9266a2a3d07cba04589e569db941481';

/// Which CI/CD tool's brand color tints `AppTheme`'s `primary`/`onPrimary`
/// (see `core/theme/app_theme.dart` and `main.dart`). `null` means "no tool
/// selected yet" — `Login`/`Signup`/`ToolSelectionScreen` render with the
/// original blue-and-white theme in that state; the app only turns
/// tool-colored once a card is actually tapped on `ToolSelectionScreen`.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore — and
/// persisting it previously meant a stale "jenkins" from an earlier session
/// made the pre-selection screens start red instead of blue, which is
/// exactly the bug this avoids.

abstract class _$ActiveToolNotifier extends $Notifier<CiTool?> {
  CiTool? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CiTool?, CiTool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CiTool?, CiTool?>,
              CiTool?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
