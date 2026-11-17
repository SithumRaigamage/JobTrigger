// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jenkins_client_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rebuilt whenever the active server changes (`docs/state-management.md`).
/// Throws if there's no active server yet — screens that depend on this
/// (via `jenkinsRepositoryProvider`, Phase 4) are expected to already gate
/// on a server being configured before reaching that point.

@ProviderFor(jenkinsClient)
final jenkinsClientProvider = JenkinsClientProvider._();

/// Rebuilt whenever the active server changes (`docs/state-management.md`).
/// Throws if there's no active server yet — screens that depend on this
/// (via `jenkinsRepositoryProvider`, Phase 4) are expected to already gate
/// on a server being configured before reaching that point.

final class JenkinsClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Rebuilt whenever the active server changes (`docs/state-management.md`).
  /// Throws if there's no active server yet — screens that depend on this
  /// (via `jenkinsRepositoryProvider`, Phase 4) are expected to already gate
  /// on a server being configured before reaching that point.
  JenkinsClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jenkinsClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jenkinsClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return jenkinsClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$jenkinsClientHash() => r'5e33437c53d928f0b19ffeb32c3eca8fd7880227';
