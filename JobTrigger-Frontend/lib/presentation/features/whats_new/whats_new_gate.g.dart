// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_new_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Package info for the gate. Separate from [packageInfoProvider] so a host
/// without the plugin (widget tests, unusual platforms) fails once: no
/// retry timer is left running behind the screen.

@ProviderFor(whatsNewPackageInfo)
final whatsNewPackageInfoProvider = WhatsNewPackageInfoProvider._();

/// Package info for the gate. Separate from [packageInfoProvider] so a host
/// without the plugin (widget tests, unusual platforms) fails once: no
/// retry timer is left running behind the screen.

final class WhatsNewPackageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PackageInfo>,
          PackageInfo,
          FutureOr<PackageInfo>
        >
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  /// Package info for the gate. Separate from [packageInfoProvider] so a host
  /// without the plugin (widget tests, unusual platforms) fails once: no
  /// retry timer is left running behind the screen.
  WhatsNewPackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'whatsNewPackageInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whatsNewPackageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return whatsNewPackageInfo(ref);
  }
}

String _$whatsNewPackageInfoHash() =>
    r'2ad0ff6392a9cd198a71356118b29ef33368de8e';
