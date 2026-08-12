// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The installed app's real version/build number — used for the profile
/// screen's version footer (P6-01). Cached for the process lifetime; the
/// installed version can't change without a fresh app launch.

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

/// The installed app's real version/build number — used for the profile
/// screen's version footer (P6-01). Cached for the process lifetime; the
/// installed version can't change without a fresh app launch.

final class PackageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PackageInfo>,
          PackageInfo,
          FutureOr<PackageInfo>
        >
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  /// The installed app's real version/build number — used for the profile
  /// screen's version footer (P6-01). Cached for the process lifetime; the
  /// installed version can't change without a fresh app launch.
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return packageInfo(ref);
  }
}

String _$packageInfoHash() => r'854bbb0e381edfdddbd736229351d6cc918a2ad1';
