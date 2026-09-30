// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nodes_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-12: nodes and their executors, refreshed every [_refreshEvery]
/// while the screen is open. The timer is cancelled on dispose.

@ProviderFor(NodesNotifier)
final nodesNotifierProvider = NodesNotifierProvider._();

/// US-JX-12: nodes and their executors, refreshed every [_refreshEvery]
/// while the screen is open. The timer is cancelled on dispose.
final class NodesNotifierProvider
    extends $AsyncNotifierProvider<NodesNotifier, NodesState> {
  /// US-JX-12: nodes and their executors, refreshed every [_refreshEvery]
  /// while the screen is open. The timer is cancelled on dispose.
  NodesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nodesNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nodesNotifierHash();

  @$internal
  @override
  NodesNotifier create() => NodesNotifier();
}

String _$nodesNotifierHash() => r'62f0bc60ee787321a7d1b3017ef4a9c0ce8399ad';

/// US-JX-12: nodes and their executors, refreshed every [_refreshEvery]
/// while the screen is open. The timer is cancelled on dispose.

abstract class _$NodesNotifier extends $AsyncNotifier<NodesState> {
  FutureOr<NodesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NodesState>, NodesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NodesState>, NodesState>,
              AsyncValue<NodesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
