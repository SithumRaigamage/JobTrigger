// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_launcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Behind a provider so tests can substitute it.

@ProviderFor(linkLauncher)
final linkLauncherProvider = LinkLauncherProvider._();

/// Behind a provider so tests can substitute it.

final class LinkLauncherProvider
    extends $FunctionalProvider<LinkLauncher, LinkLauncher, LinkLauncher>
    with $Provider<LinkLauncher> {
  /// Behind a provider so tests can substitute it.
  LinkLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkLauncherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkLauncherHash();

  @$internal
  @override
  $ProviderElement<LinkLauncher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LinkLauncher create(Ref ref) {
    return linkLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkLauncher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkLauncher>(value),
    );
  }
}

String _$linkLauncherHash() => r'58846080fcc137b9de92614dd44d2670aa63209e';
