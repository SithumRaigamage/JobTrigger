// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-AUTH-08: the "Forgot password?" form. `true` once the request went
/// through — the screen then says to check the inbox, worded so it never
/// confirms that the email has an account (the backend doesn't either).

@ProviderFor(ForgotPasswordNotifier)
final forgotPasswordNotifierProvider = ForgotPasswordNotifierProvider._();

/// US-AUTH-08: the "Forgot password?" form. `true` once the request went
/// through — the screen then says to check the inbox, worded so it never
/// confirms that the email has an account (the backend doesn't either).
final class ForgotPasswordNotifierProvider
    extends $AsyncNotifierProvider<ForgotPasswordNotifier, bool> {
  /// US-AUTH-08: the "Forgot password?" form. `true` once the request went
  /// through — the screen then says to check the inbox, worded so it never
  /// confirms that the email has an account (the backend doesn't either).
  ForgotPasswordNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forgotPasswordNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forgotPasswordNotifierHash();

  @$internal
  @override
  ForgotPasswordNotifier create() => ForgotPasswordNotifier();
}

String _$forgotPasswordNotifierHash() =>
    r'61270a9c8c4757d3c5c42a1ef962fc532444a46b';

/// US-AUTH-08: the "Forgot password?" form. `true` once the request went
/// through — the screen then says to check the inbox, worded so it never
/// confirms that the email has an account (the backend doesn't either).

abstract class _$ForgotPasswordNotifier extends $AsyncNotifier<bool> {
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
