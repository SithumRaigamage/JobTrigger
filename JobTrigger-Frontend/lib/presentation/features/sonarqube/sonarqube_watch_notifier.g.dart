// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_watch_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `US-SQ-WATCH-01`: projects watched for a failing quality gate. While the
/// app is alive it checks every [_checkEvery]; while it is closed the shared
/// background task takes over at the OS's pace. Same discipline as
/// `BuildWatchNotifier`: one pass at a time, serialized writes.

@ProviderFor(SonarQubeWatchNotifier)
final sonarQubeWatchNotifierProvider = SonarQubeWatchNotifierProvider._();

/// `US-SQ-WATCH-01`: projects watched for a failing quality gate. While the
/// app is alive it checks every [_checkEvery]; while it is closed the shared
/// background task takes over at the OS's pace. Same discipline as
/// `BuildWatchNotifier`: one pass at a time, serialized writes.
final class SonarQubeWatchNotifierProvider
    extends
        $NotifierProvider<SonarQubeWatchNotifier, List<SonarQubeProjectWatch>> {
  /// `US-SQ-WATCH-01`: projects watched for a failing quality gate. While the
  /// app is alive it checks every [_checkEvery]; while it is closed the shared
  /// background task takes over at the OS's pace. Same discipline as
  /// `BuildWatchNotifier`: one pass at a time, serialized writes.
  SonarQubeWatchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeWatchNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeWatchNotifierHash();

  @$internal
  @override
  SonarQubeWatchNotifier create() => SonarQubeWatchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SonarQubeProjectWatch> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SonarQubeProjectWatch>>(value),
    );
  }
}

String _$sonarQubeWatchNotifierHash() =>
    r'dfc4c77f25425563f08cd18717052fe9ec7a57b1';

/// `US-SQ-WATCH-01`: projects watched for a failing quality gate. While the
/// app is alive it checks every [_checkEvery]; while it is closed the shared
/// background task takes over at the OS's pace. Same discipline as
/// `BuildWatchNotifier`: one pass at a time, serialized writes.

abstract class _$SonarQubeWatchNotifier
    extends $Notifier<List<SonarQubeProjectWatch>> {
  List<SonarQubeProjectWatch> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<List<SonarQubeProjectWatch>, List<SonarQubeProjectWatch>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<SonarQubeProjectWatch>,
                List<SonarQubeProjectWatch>
              >,
              List<SonarQubeProjectWatch>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
