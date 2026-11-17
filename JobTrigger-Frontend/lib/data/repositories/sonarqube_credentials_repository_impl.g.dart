// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_credentials_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sonarQubeCredentialsRepository)
final sonarQubeCredentialsRepositoryProvider =
    SonarQubeCredentialsRepositoryProvider._();

final class SonarQubeCredentialsRepositoryProvider
    extends
        $FunctionalProvider<
          SonarQubeCredentialsRepository,
          SonarQubeCredentialsRepository,
          SonarQubeCredentialsRepository
        >
    with $Provider<SonarQubeCredentialsRepository> {
  SonarQubeCredentialsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeCredentialsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeCredentialsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SonarQubeCredentialsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SonarQubeCredentialsRepository create(Ref ref) {
    return sonarQubeCredentialsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeCredentialsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeCredentialsRepository>(
        value,
      ),
    );
  }
}

String _$sonarQubeCredentialsRepositoryHash() =>
    r'5ff278920c4aa1f6394ec1af67f24e12a0b4a247';
