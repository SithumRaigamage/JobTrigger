// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_widget_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `US-SQ-WIDGET-01`: keeps the pinned-projects widget's snapshot in step
/// with the pins and their gate verdicts, the way [homeWidgetSync] does for
/// Jenkins jobs. The widget renders the snapshot and never calls SonarQube,
/// and holds no credential. Watched from `main.dart`.

@ProviderFor(sonarQubeWidgetSync)
final sonarQubeWidgetSyncProvider = SonarQubeWidgetSyncProvider._();

/// `US-SQ-WIDGET-01`: keeps the pinned-projects widget's snapshot in step
/// with the pins and their gate verdicts, the way [homeWidgetSync] does for
/// Jenkins jobs. The widget renders the snapshot and never calls SonarQube,
/// and holds no credential. Watched from `main.dart`.

final class SonarQubeWidgetSyncProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// `US-SQ-WIDGET-01`: keeps the pinned-projects widget's snapshot in step
  /// with the pins and their gate verdicts, the way [homeWidgetSync] does for
  /// Jenkins jobs. The widget renders the snapshot and never calls SonarQube,
  /// and holds no credential. Watched from `main.dart`.
  SonarQubeWidgetSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeWidgetSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeWidgetSyncHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return sonarQubeWidgetSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sonarQubeWidgetSyncHash() =>
    r'2fea3ef2f9a2ce6a3e5b9d2a6e6d0e9b4d4e458e';
