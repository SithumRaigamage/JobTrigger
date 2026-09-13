// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Form-submit state (loading/error) for the login screen — see
/// `docs/state-management.md`'s "Feature: auth" section. Owns nothing about
/// the session itself; on success it delegates to `authNotifierProvider`.

@ProviderFor(LoginNotifier)
final loginNotifierProvider = LoginNotifierProvider._();

/// Form-submit state (loading/error) for the login screen — see
/// `docs/state-management.md`'s "Feature: auth" section. Owns nothing about
/// the session itself; on success it delegates to `authNotifierProvider`.
final class LoginNotifierProvider
    extends $AsyncNotifierProvider<LoginNotifier, void> {
  /// Form-submit state (loading/error) for the login screen — see
  /// `docs/state-management.md`'s "Feature: auth" section. Owns nothing about
  /// the session itself; on success it delegates to `authNotifierProvider`.
  LoginNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginNotifierHash();

  @$internal
  @override
  LoginNotifier create() => LoginNotifier();
}

String _$loginNotifierHash() => r'325e95ea2510b7c2569f7484b6953a78be41cd2b';

/// Form-submit state (loading/error) for the login screen — see
/// `docs/state-management.md`'s "Feature: auth" section. Owns nothing about
/// the session itself; on success it delegates to `authNotifierProvider`.

abstract class _$LoginNotifier extends $AsyncNotifier<void> {
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
