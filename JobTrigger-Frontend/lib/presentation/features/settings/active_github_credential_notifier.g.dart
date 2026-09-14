// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_github_credential_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently active GitHub credential. Mirrors `ActiveServerNotifier`'s
/// shape exactly (`US-GH-CRED-03`) — entirely independent state, its own
/// `SharedPreferences` key, its own fallback logic. Switching this never
/// touches `ActiveServerNotifier`'s state and vice versa: two unrelated
/// "active" concepts, not a single "active CI tool" selector
/// (`NFR-SEC-03`).

@ProviderFor(ActiveGitHubCredentialNotifier)
final activeGitHubCredentialNotifierProvider =
    ActiveGitHubCredentialNotifierProvider._();

/// Currently active GitHub credential. Mirrors `ActiveServerNotifier`'s
/// shape exactly (`US-GH-CRED-03`) — entirely independent state, its own
/// `SharedPreferences` key, its own fallback logic. Switching this never
/// touches `ActiveServerNotifier`'s state and vice versa: two unrelated
/// "active" concepts, not a single "active CI tool" selector
/// (`NFR-SEC-03`).
final class ActiveGitHubCredentialNotifierProvider
    extends
        $NotifierProvider<ActiveGitHubCredentialNotifier, GitHubCredential?> {
  /// Currently active GitHub credential. Mirrors `ActiveServerNotifier`'s
  /// shape exactly (`US-GH-CRED-03`) — entirely independent state, its own
  /// `SharedPreferences` key, its own fallback logic. Switching this never
  /// touches `ActiveServerNotifier`'s state and vice versa: two unrelated
  /// "active" concepts, not a single "active CI tool" selector
  /// (`NFR-SEC-03`).
  ActiveGitHubCredentialNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGitHubCredentialNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGitHubCredentialNotifierHash();

  @$internal
  @override
  ActiveGitHubCredentialNotifier create() => ActiveGitHubCredentialNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubCredential? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubCredential?>(value),
    );
  }
}

String _$activeGitHubCredentialNotifierHash() =>
    r'3db22ce42858e8c56bf5d4b48cce6d0da752f2a6';

/// Currently active GitHub credential. Mirrors `ActiveServerNotifier`'s
/// shape exactly (`US-GH-CRED-03`) — entirely independent state, its own
/// `SharedPreferences` key, its own fallback logic. Switching this never
/// touches `ActiveServerNotifier`'s state and vice versa: two unrelated
/// "active" concepts, not a single "active CI tool" selector
/// (`NFR-SEC-03`).

abstract class _$ActiveGitHubCredentialNotifier
    extends $Notifier<GitHubCredential?> {
  GitHubCredential? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GitHubCredential?, GitHubCredential?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GitHubCredential?, GitHubCredential?>,
              GitHubCredential?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
