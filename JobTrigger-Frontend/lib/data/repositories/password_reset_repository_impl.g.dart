// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(passwordResetRepository)
final passwordResetRepositoryProvider = PasswordResetRepositoryProvider._();

final class PasswordResetRepositoryProvider
    extends
        $FunctionalProvider<
          PasswordResetRepository,
          PasswordResetRepository,
          PasswordResetRepository
        >
    with $Provider<PasswordResetRepository> {
  PasswordResetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordResetRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordResetRepositoryHash();

  @$internal
  @override
  $ProviderElement<PasswordResetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PasswordResetRepository create(Ref ref) {
    return passwordResetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordResetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordResetRepository>(value),
    );
  }
}

String _$passwordResetRepositoryHash() =>
    r'acef6f056a567c3d363d5d7a7b2aa8851ebd7d9c';
