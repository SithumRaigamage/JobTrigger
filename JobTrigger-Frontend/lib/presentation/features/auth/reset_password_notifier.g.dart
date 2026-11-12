// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_password_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-AUTH-08: choosing a new password from the emailed link
/// (`jobtrigger://app/reset-password?token=…`). `true` once it's reset.

@ProviderFor(ResetPasswordNotifier)
final resetPasswordNotifierProvider = ResetPasswordNotifierProvider._();

/// US-AUTH-08: choosing a new password from the emailed link
/// (`jobtrigger://app/reset-password?token=…`). `true` once it's reset.
final class ResetPasswordNotifierProvider
    extends $AsyncNotifierProvider<ResetPasswordNotifier, bool> {
  /// US-AUTH-08: choosing a new password from the emailed link
  /// (`jobtrigger://app/reset-password?token=…`). `true` once it's reset.
  ResetPasswordNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetPasswordNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetPasswordNotifierHash();

  @$internal
  @override
  ResetPasswordNotifier create() => ResetPasswordNotifier();
}

String _$resetPasswordNotifierHash() =>
    r'5625786fcf34b684155534b33d6b502751aad913';

/// US-AUTH-08: choosing a new password from the emailed link
/// (`jobtrigger://app/reset-password?token=…`). `true` once it's reset.

abstract class _$ResetPasswordNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
