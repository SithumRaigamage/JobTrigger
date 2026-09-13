// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Same shape as `LoginNotifier`, plus the signup-specific
/// password-length/confirm-match rules — ported from `SignupViewModel.swift`.

@ProviderFor(SignupNotifier)
final signupNotifierProvider = SignupNotifierProvider._();

/// Same shape as `LoginNotifier`, plus the signup-specific
/// password-length/confirm-match rules — ported from `SignupViewModel.swift`.
final class SignupNotifierProvider
    extends $AsyncNotifierProvider<SignupNotifier, void> {
  /// Same shape as `LoginNotifier`, plus the signup-specific
  /// password-length/confirm-match rules — ported from `SignupViewModel.swift`.
  SignupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signupNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signupNotifierHash();

  @$internal
  @override
  SignupNotifier create() => SignupNotifier();
}

String _$signupNotifierHash() => r'c79d0017b57238b0d28430f8e611c354e31529d7';

/// Same shape as `LoginNotifier`, plus the signup-specific
/// password-length/confirm-match rules — ported from `SignupViewModel.swift`.

abstract class _$SignupNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
