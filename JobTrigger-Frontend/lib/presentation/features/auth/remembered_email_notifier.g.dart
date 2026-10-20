// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remembered_email_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Remember me" on the login screen: remembers the **email only**.
///
/// The password is deliberately never persisted (AUD-01, `CLAUDE.md` §7) —
/// a stored JWT already keeps the session alive across restarts
/// (US-AUTH-03), so a saved password would add exposure and no value. The
/// email isn't a secret, so `shared_preferences` is the right store for it,
/// same as `ThemeNotifier`.

@ProviderFor(RememberedEmailNotifier)
final rememberedEmailNotifierProvider = RememberedEmailNotifierProvider._();

/// "Remember me" on the login screen: remembers the **email only**.
///
/// The password is deliberately never persisted (AUD-01, `CLAUDE.md` §7) —
/// a stored JWT already keeps the session alive across restarts
/// (US-AUTH-03), so a saved password would add exposure and no value. The
/// email isn't a secret, so `shared_preferences` is the right store for it,
/// same as `ThemeNotifier`.
final class RememberedEmailNotifierProvider
    extends $AsyncNotifierProvider<RememberedEmailNotifier, String?> {
  /// "Remember me" on the login screen: remembers the **email only**.
  ///
  /// The password is deliberately never persisted (AUD-01, `CLAUDE.md` §7) —
  /// a stored JWT already keeps the session alive across restarts
  /// (US-AUTH-03), so a saved password would add exposure and no value. The
  /// email isn't a secret, so `shared_preferences` is the right store for it,
  /// same as `ThemeNotifier`.
  RememberedEmailNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rememberedEmailNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rememberedEmailNotifierHash();

  @$internal
  @override
  RememberedEmailNotifier create() => RememberedEmailNotifier();
}

String _$rememberedEmailNotifierHash() =>
    r'3ce171b94a692d429f4829be0f10805946589af6';

/// "Remember me" on the login screen: remembers the **email only**.
///
/// The password is deliberately never persisted (AUD-01, `CLAUDE.md` §7) —
/// a stored JWT already keeps the session alive across restarts
/// (US-AUTH-03), so a saved password would add exposure and no value. The
/// email isn't a secret, so `shared_preferences` is the right store for it,
/// same as `ThemeNotifier`.

abstract class _$RememberedEmailNotifier extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
