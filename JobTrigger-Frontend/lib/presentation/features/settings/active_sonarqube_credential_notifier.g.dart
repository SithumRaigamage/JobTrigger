// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_sonarqube_credential_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently active SonarQube credential. Mirrors
/// `ActiveGitHubCredentialNotifier`'s shape exactly (`US-SQ-CRED-03`) —
/// entirely independent state, its own `SharedPreferences` key, its own
/// fallback logic. Switching this never touches any other tool's active
/// credential and vice versa (`NFR-SEC-03`).

@ProviderFor(ActiveSonarQubeCredentialNotifier)
final activeSonarQubeCredentialNotifierProvider =
    ActiveSonarQubeCredentialNotifierProvider._();

/// Currently active SonarQube credential. Mirrors
/// `ActiveGitHubCredentialNotifier`'s shape exactly (`US-SQ-CRED-03`) —
/// entirely independent state, its own `SharedPreferences` key, its own
/// fallback logic. Switching this never touches any other tool's active
/// credential and vice versa (`NFR-SEC-03`).
final class ActiveSonarQubeCredentialNotifierProvider
    extends
        $NotifierProvider<
          ActiveSonarQubeCredentialNotifier,
          SonarQubeCredential?
        > {
  /// Currently active SonarQube credential. Mirrors
  /// `ActiveGitHubCredentialNotifier`'s shape exactly (`US-SQ-CRED-03`) —
  /// entirely independent state, its own `SharedPreferences` key, its own
  /// fallback logic. Switching this never touches any other tool's active
  /// credential and vice versa (`NFR-SEC-03`).
  ActiveSonarQubeCredentialNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSonarQubeCredentialNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$activeSonarQubeCredentialNotifierHash();

  @$internal
  @override
  ActiveSonarQubeCredentialNotifier create() =>
      ActiveSonarQubeCredentialNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeCredential? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeCredential?>(value),
    );
  }
}

String _$activeSonarQubeCredentialNotifierHash() =>
    r'86426e446386f3cc6052baaf87549dc2dddb6055';

/// Currently active SonarQube credential. Mirrors
/// `ActiveGitHubCredentialNotifier`'s shape exactly (`US-SQ-CRED-03`) —
/// entirely independent state, its own `SharedPreferences` key, its own
/// fallback logic. Switching this never touches any other tool's active
/// credential and vice versa (`NFR-SEC-03`).

abstract class _$ActiveSonarQubeCredentialNotifier
    extends $Notifier<SonarQubeCredential?> {
  SonarQubeCredential? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SonarQubeCredential?, SonarQubeCredential?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SonarQubeCredential?, SonarQubeCredential?>,
              SonarQubeCredential?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
