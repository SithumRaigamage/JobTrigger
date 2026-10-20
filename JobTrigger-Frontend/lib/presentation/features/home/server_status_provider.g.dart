// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-18: the active server's version and quiet-down state. Additive:
/// a failure yields an empty status rather than an error, so it never
/// blocks Home or Settings. Rebuilt when the active server changes.

@ProviderFor(serverStatus)
final serverStatusProvider = ServerStatusProvider._();

/// US-JX-18: the active server's version and quiet-down state. Additive:
/// a failure yields an empty status rather than an error, so it never
/// blocks Home or Settings. Rebuilt when the active server changes.

final class ServerStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ServerStatus>,
          ServerStatus,
          FutureOr<ServerStatus>
        >
    with $FutureModifier<ServerStatus>, $FutureProvider<ServerStatus> {
  /// US-JX-18: the active server's version and quiet-down state. Additive:
  /// a failure yields an empty status rather than an error, so it never
  /// blocks Home or Settings. Rebuilt when the active server changes.
  ServerStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverStatusHash();

  @$internal
  @override
  $FutureProviderElement<ServerStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ServerStatus> create(Ref ref) {
    return serverStatus(ref);
  }
}

String _$serverStatusHash() => r'e2c2ffbb02a54089f94b2568382c23632b43bbe2';
