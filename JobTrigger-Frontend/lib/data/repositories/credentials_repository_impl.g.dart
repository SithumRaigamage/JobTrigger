// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(credentialsRepository)
final credentialsRepositoryProvider = CredentialsRepositoryProvider._();

final class CredentialsRepositoryProvider
    extends
        $FunctionalProvider<
          CredentialsRepository,
          CredentialsRepository,
          CredentialsRepository
        >
    with $Provider<CredentialsRepository> {
  CredentialsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CredentialsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CredentialsRepository create(Ref ref) {
    return credentialsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CredentialsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CredentialsRepository>(value),
    );
  }
}

String _$credentialsRepositoryHash() =>
    r'e852e333da8df21f14b3fdb98c3488b870a0d5e8';
