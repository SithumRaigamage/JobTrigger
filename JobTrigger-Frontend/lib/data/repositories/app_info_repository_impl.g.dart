// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appInfoRepository)
final appInfoRepositoryProvider = AppInfoRepositoryProvider._();

final class AppInfoRepositoryProvider
    extends
        $FunctionalProvider<
          AppInfoRepository,
          AppInfoRepository,
          AppInfoRepository
        >
    with $Provider<AppInfoRepository> {
  AppInfoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInfoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInfoRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppInfoRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppInfoRepository create(Ref ref) {
    return appInfoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppInfoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppInfoRepository>(value),
    );
  }
}

String _$appInfoRepositoryHash() => r'b973f9d8c84204af1408069ed306d9e22eaa32f8';
