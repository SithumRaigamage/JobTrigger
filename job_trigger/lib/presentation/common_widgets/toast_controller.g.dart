// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toast_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the single currently-visible toast, watched by `ToastOverlay`.
/// Matches the old app's `NotificationManager`: only one toast is shown at a
/// time — a new one replaces whatever is showing rather than queuing.

@ProviderFor(CurrentToast)
final currentToastProvider = CurrentToastProvider._();

/// Holds the single currently-visible toast, watched by `ToastOverlay`.
/// Matches the old app's `NotificationManager`: only one toast is shown at a
/// time — a new one replaces whatever is showing rather than queuing.
final class CurrentToastProvider
    extends $NotifierProvider<CurrentToast, ToastMessage?> {
  /// Holds the single currently-visible toast, watched by `ToastOverlay`.
  /// Matches the old app's `NotificationManager`: only one toast is shown at a
  /// time — a new one replaces whatever is showing rather than queuing.
  CurrentToastProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentToastProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentToastHash();

  @$internal
  @override
  CurrentToast create() => CurrentToast();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToastMessage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToastMessage?>(value),
    );
  }
}

String _$currentToastHash() => r'9b9dd082cbbb043b3c3b79e919592afb4cd0b26f';

/// Holds the single currently-visible toast, watched by `ToastOverlay`.
/// Matches the old app's `NotificationManager`: only one toast is shown at a
/// time — a new one replaces whatever is showing rather than queuing.

abstract class _$CurrentToast extends $Notifier<ToastMessage?> {
  ToastMessage? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ToastMessage?, ToastMessage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ToastMessage?, ToastMessage?>,
              ToastMessage?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(toastController)
final toastControllerProvider = ToastControllerProvider._();

final class ToastControllerProvider
    extends
        $FunctionalProvider<ToastController, ToastController, ToastController>
    with $Provider<ToastController> {
  ToastControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toastControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toastControllerHash();

  @$internal
  @override
  $ProviderElement<ToastController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ToastController create(Ref ref) {
    return toastController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToastController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToastController>(value),
    );
  }
}

String _$toastControllerHash() => r'f0ec4a8f4927fd1152d1897efe03a685221ba6cf';
