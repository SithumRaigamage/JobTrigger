// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_client_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rebuilt whenever the active GitHub credential changes — mirrors
/// `jenkinsClientProvider` exactly. Throws if there's no active credential
/// yet; screens that depend on this are expected to already gate on a
/// credential being configured before reaching that point.

@ProviderFor(gitHubClient)
final gitHubClientProvider = GitHubClientProvider._();

/// Rebuilt whenever the active GitHub credential changes — mirrors
/// `jenkinsClientProvider` exactly. Throws if there's no active credential
/// yet; screens that depend on this are expected to already gate on a
/// credential being configured before reaching that point.

final class GitHubClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Rebuilt whenever the active GitHub credential changes — mirrors
  /// `jenkinsClientProvider` exactly. Throws if there's no active credential
  /// yet; screens that depend on this are expected to already gate on a
  /// credential being configured before reaching that point.
  GitHubClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return gitHubClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$gitHubClientHash() => r'3eb4ade19233a1f16f279ee91415b0bc67e3c5b4';
