// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-21: the biometric app lock. Locks on a cold start and on resume
/// after [AppLockSettings.timeout] in the background; optionally re-prompts
/// before sensitive actions. It gates the UI only: secrets stay in secure
/// storage either way.

@ProviderFor(AppLockNotifier)
final appLockNotifierProvider = AppLockNotifierProvider._();

/// US-JX-21: the biometric app lock. Locks on a cold start and on resume
/// after [AppLockSettings.timeout] in the background; optionally re-prompts
/// before sensitive actions. It gates the UI only: secrets stay in secure
/// storage either way.
final class AppLockNotifierProvider
    extends $NotifierProvider<AppLockNotifier, AppLockState> {
  /// US-JX-21: the biometric app lock. Locks on a cold start and on resume
  /// after [AppLockSettings.timeout] in the background; optionally re-prompts
  /// before sensitive actions. It gates the UI only: secrets stay in secure
  /// storage either way.
  AppLockNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockNotifierHash();

  @$internal
  @override
  AppLockNotifier create() => AppLockNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLockState>(value),
    );
  }
}

String _$appLockNotifierHash() => r'e7226738d56a8cd87386097afdfadbe88cfbe3b6';

/// US-JX-21: the biometric app lock. Locks on a cold start and on resume
/// after [AppLockSettings.timeout] in the background; optionally re-prompts
/// before sensitive actions. It gates the UI only: secrets stay in secure
/// storage either way.

abstract class _$AppLockNotifier extends $Notifier<AppLockState> {
  AppLockState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppLockState, AppLockState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLockState, AppLockState>,
              AppLockState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
