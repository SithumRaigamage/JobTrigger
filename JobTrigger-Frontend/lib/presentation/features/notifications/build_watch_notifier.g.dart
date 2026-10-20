// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_watch_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The background scheduler, behind a provider so tests can stub it.

@ProviderFor(backgroundWatchScheduler)
final backgroundWatchSchedulerProvider = BackgroundWatchSchedulerProvider._();

/// The background scheduler, behind a provider so tests can stub it.

final class BackgroundWatchSchedulerProvider
    extends
        $FunctionalProvider<
          BackgroundWatchScheduler,
          BackgroundWatchScheduler,
          BackgroundWatchScheduler
        >
    with $Provider<BackgroundWatchScheduler> {
  /// The background scheduler, behind a provider so tests can stub it.
  BackgroundWatchSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundWatchSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundWatchSchedulerHash();

  @$internal
  @override
  $ProviderElement<BackgroundWatchScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundWatchScheduler create(Ref ref) {
    return backgroundWatchScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundWatchScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundWatchScheduler>(value),
    );
  }
}

String _$backgroundWatchSchedulerHash() =>
    r'3bb9aa2ea76a58ae33095cfd683a9abdb0dc2a75';

/// US-JX-10: the builds and jobs the user wants a notification for. While
/// the app is alive, checks every [_checkEvery]. While it's suspended, the
/// background task takes over at the OS's pace. The timer is cancelled on
/// dispose, the same discipline as the other pollers.

@ProviderFor(BuildWatchNotifier)
final buildWatchNotifierProvider = BuildWatchNotifierProvider._();

/// US-JX-10: the builds and jobs the user wants a notification for. While
/// the app is alive, checks every [_checkEvery]. While it's suspended, the
/// background task takes over at the OS's pace. The timer is cancelled on
/// dispose, the same discipline as the other pollers.
final class BuildWatchNotifierProvider
    extends $NotifierProvider<BuildWatchNotifier, List<BuildWatch>> {
  /// US-JX-10: the builds and jobs the user wants a notification for. While
  /// the app is alive, checks every [_checkEvery]. While it's suspended, the
  /// background task takes over at the OS's pace. The timer is cancelled on
  /// dispose, the same discipline as the other pollers.
  BuildWatchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildWatchNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildWatchNotifierHash();

  @$internal
  @override
  BuildWatchNotifier create() => BuildWatchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BuildWatch> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BuildWatch>>(value),
    );
  }
}

String _$buildWatchNotifierHash() =>
    r'a03d168048b0942e8b4a0f633097e06f50854d64';

/// US-JX-10: the builds and jobs the user wants a notification for. While
/// the app is alive, checks every [_checkEvery]. While it's suspended, the
/// background task takes over at the OS's pace. The timer is cancelled on
/// dispose, the same discipline as the other pollers.

abstract class _$BuildWatchNotifier extends $Notifier<List<BuildWatch>> {
  List<BuildWatch> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<BuildWatch>, List<BuildWatch>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BuildWatch>, List<BuildWatch>>,
              List<BuildWatch>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
