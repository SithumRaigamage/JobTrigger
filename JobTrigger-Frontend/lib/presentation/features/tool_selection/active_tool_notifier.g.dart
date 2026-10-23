// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_tool_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which CI/CD tool the session is using: it picks what the Home and
/// History tabs show and which credentials Settings and Profile manage.
/// `null` means "no tool selected yet"; screens treat it as Jenkins.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore.
///
/// Kept alive for the session: the choice is made on
/// `ToolSelectionScreen`, which only reads this, and the screens that watch
/// it build a frame later. Auto-disposed, the state was dropped in between
/// and a switch to GitHub Actions silently fell back to Jenkins — hidden
/// until P14-02 removed the theme's app-wide watch that kept it alive.

@ProviderFor(ActiveToolNotifier)
final activeToolNotifierProvider = ActiveToolNotifierProvider._();

/// Which CI/CD tool the session is using: it picks what the Home and
/// History tabs show and which credentials Settings and Profile manage.
/// `null` means "no tool selected yet"; screens treat it as Jenkins.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore.
///
/// Kept alive for the session: the choice is made on
/// `ToolSelectionScreen`, which only reads this, and the screens that watch
/// it build a frame later. Auto-disposed, the state was dropped in between
/// and a switch to GitHub Actions silently fell back to Jenkins — hidden
/// until P14-02 removed the theme's app-wide watch that kept it alive.
final class ActiveToolNotifierProvider
    extends $NotifierProvider<ActiveToolNotifier, CiTool?> {
  /// Which CI/CD tool the session is using: it picks what the Home and
  /// History tabs show and which credentials Settings and Profile manage.
  /// `null` means "no tool selected yet"; screens treat it as Jenkins.
  ///
  /// Deliberately in-memory only, *not* persisted: an authenticated user is
  /// always routed back through `ToolSelectionScreen` after a cold launch
  /// (see `app_router.dart`'s redirect), so there's nothing to restore.
  ///
  /// Kept alive for the session: the choice is made on
  /// `ToolSelectionScreen`, which only reads this, and the screens that watch
  /// it build a frame later. Auto-disposed, the state was dropped in between
  /// and a switch to GitHub Actions silently fell back to Jenkins — hidden
  /// until P14-02 removed the theme's app-wide watch that kept it alive.
  ActiveToolNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeToolNotifierProvider',
        isAutoDispose: false,
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
    r'6b90ba983df72f58b2539051686d31da752287f6';

/// Which CI/CD tool the session is using: it picks what the Home and
/// History tabs show and which credentials Settings and Profile manage.
/// `null` means "no tool selected yet"; screens treat it as Jenkins.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore.
///
/// Kept alive for the session: the choice is made on
/// `ToolSelectionScreen`, which only reads this, and the screens that watch
/// it build a frame later. Auto-disposed, the state was dropped in between
/// and a switch to GitHub Actions silently fell back to Jenkins — hidden
/// until P14-02 removed the theme's app-wide watch that kept it alive.

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
