// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_mode_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The value read from `shared_preferences` before the app starts, so the
/// first frame and the session check already know whether demo mode is on.
/// `main()` overrides it; tests default to off.

@ProviderFor(demoModeInitial)
final demoModeInitialProvider = DemoModeInitialProvider._();

/// The value read from `shared_preferences` before the app starts, so the
/// first frame and the session check already know whether demo mode is on.
/// `main()` overrides it; tests default to off.

final class DemoModeInitialProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// The value read from `shared_preferences` before the app starts, so the
  /// first frame and the session check already know whether demo mode is on.
  /// `main()` overrides it; tests default to off.
  DemoModeInitialProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoModeInitialProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoModeInitialHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return demoModeInitial(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$demoModeInitialHash() => r'a1689ea4778e699249b952f54cf34a8815a7d006';

/// E2 (PE-11): whether the app runs on built-in sample data. While on, the
/// repository providers return the in-memory demo repositories, so no
/// request leaves the device and no stored credential is read. Entered only
/// from the sign-in screen and left with "Exit demo".

@ProviderFor(DemoModeNotifier)
final demoModeNotifierProvider = DemoModeNotifierProvider._();

/// E2 (PE-11): whether the app runs on built-in sample data. While on, the
/// repository providers return the in-memory demo repositories, so no
/// request leaves the device and no stored credential is read. Entered only
/// from the sign-in screen and left with "Exit demo".
final class DemoModeNotifierProvider
    extends $NotifierProvider<DemoModeNotifier, bool> {
  /// E2 (PE-11): whether the app runs on built-in sample data. While on, the
  /// repository providers return the in-memory demo repositories, so no
  /// request leaves the device and no stored credential is read. Entered only
  /// from the sign-in screen and left with "Exit demo".
  DemoModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoModeNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoModeNotifierHash();

  @$internal
  @override
  DemoModeNotifier create() => DemoModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$demoModeNotifierHash() => r'23f9fd22a8ac24b2d6229637616aa00a215a7d82';

/// E2 (PE-11): whether the app runs on built-in sample data. While on, the
/// repository providers return the in-memory demo repositories, so no
/// request leaves the device and no stored credential is read. Entered only
/// from the sign-in screen and left with "Exit demo".

abstract class _$DemoModeNotifier extends $Notifier<bool> {
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
