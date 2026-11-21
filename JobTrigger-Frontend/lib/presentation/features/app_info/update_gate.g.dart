// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PROF-03: whether the backend's `minSupportedVersion` is newer than
/// the installed app. False while loading and on any failure: an outage
/// or an old backend never blocks the app.

@ProviderFor(updateRequired)
final updateRequiredProvider = UpdateRequiredProvider._();

/// US-PROF-03: whether the backend's `minSupportedVersion` is newer than
/// the installed app. False while loading and on any failure: an outage
/// or an old backend never blocks the app.

final class UpdateRequiredProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// US-PROF-03: whether the backend's `minSupportedVersion` is newer than
  /// the installed app. False while loading and on any failure: an outage
  /// or an old backend never blocks the app.
  UpdateRequiredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateRequiredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateRequiredHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return updateRequired(ref);
  }
}

String _$updateRequiredHash() => r'e6ff20f29fc308c279b399679a3a3fb18ec4c446';
