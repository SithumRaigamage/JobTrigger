// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_review_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminReviewRepository)
final adminReviewRepositoryProvider = AdminReviewRepositoryProvider._();

final class AdminReviewRepositoryProvider
    extends
        $FunctionalProvider<
          AdminReviewRepository,
          AdminReviewRepository,
          AdminReviewRepository
        >
    with $Provider<AdminReviewRepository> {
  AdminReviewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminReviewRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminReviewRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminReviewRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminReviewRepository create(Ref ref) {
    return adminReviewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminReviewRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminReviewRepository>(value),
    );
  }
}

String _$adminReviewRepositoryHash() =>
    r'd6ef8009d65d0eb716a8ec1c7948674b0ce46c5e';
