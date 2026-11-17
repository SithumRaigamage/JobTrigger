// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_run_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local milestones for the first-run card. The "connected" and "alerts"
/// steps are read live from the credential and watch providers; only the
/// "triggered" and "dismissed" flags need storing.
///
/// Follows the synchronous-build pattern from `ServerSafetyNotifier`: state
/// starts empty and fills from `shared_preferences` in the background, so
/// widgets can `ref.watch` it without handling an `AsyncValue`.

@ProviderFor(FirstRunNotifier)
final firstRunNotifierProvider = FirstRunNotifierProvider._();

/// Local milestones for the first-run card. The "connected" and "alerts"
/// steps are read live from the credential and watch providers; only the
/// "triggered" and "dismissed" flags need storing.
///
/// Follows the synchronous-build pattern from `ServerSafetyNotifier`: state
/// starts empty and fills from `shared_preferences` in the background, so
/// widgets can `ref.watch` it without handling an `AsyncValue`.
final class FirstRunNotifierProvider
    extends $NotifierProvider<FirstRunNotifier, FirstRunState> {
  /// Local milestones for the first-run card. The "connected" and "alerts"
  /// steps are read live from the credential and watch providers; only the
  /// "triggered" and "dismissed" flags need storing.
  ///
  /// Follows the synchronous-build pattern from `ServerSafetyNotifier`: state
  /// starts empty and fills from `shared_preferences` in the background, so
  /// widgets can `ref.watch` it without handling an `AsyncValue`.
  FirstRunNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstRunNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstRunNotifierHash();

  @$internal
  @override
  FirstRunNotifier create() => FirstRunNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirstRunState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirstRunState>(value),
    );
  }
}

String _$firstRunNotifierHash() => r'c1807cd386e0a4ee589b377029a0f63d6f3c2b7e';

/// Local milestones for the first-run card. The "connected" and "alerts"
/// steps are read live from the credential and watch providers; only the
/// "triggered" and "dismissed" flags need storing.
///
/// Follows the synchronous-build pattern from `ServerSafetyNotifier`: state
/// starts empty and fills from `shared_preferences` in the background, so
/// widgets can `ref.watch` it without handling an `AsyncValue`.

abstract class _$FirstRunNotifier extends $Notifier<FirstRunState> {
  FirstRunState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FirstRunState, FirstRunState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FirstRunState, FirstRunState>,
              FirstRunState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
