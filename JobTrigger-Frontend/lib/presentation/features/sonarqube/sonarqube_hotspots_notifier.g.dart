// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_hotspots_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A project's security hotspots (`US-SQ-HOTSPOT-01`), to review or already
/// reviewed. Read-only: reviewing is `US-SQ-WRITE-04`.

@ProviderFor(SonarQubeHotspotsNotifier)
final sonarQubeHotspotsNotifierProvider = SonarQubeHotspotsNotifierFamily._();

/// A project's security hotspots (`US-SQ-HOTSPOT-01`), to review or already
/// reviewed. Read-only: reviewing is `US-SQ-WRITE-04`.
final class SonarQubeHotspotsNotifierProvider
    extends
        $AsyncNotifierProvider<
          SonarQubeHotspotsNotifier,
          SonarQubeHotspotsState
        > {
  /// A project's security hotspots (`US-SQ-HOTSPOT-01`), to review or already
  /// reviewed. Read-only: reviewing is `US-SQ-WRITE-04`.
  SonarQubeHotspotsNotifierProvider._({
    required SonarQubeHotspotsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeHotspotsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeHotspotsNotifierHash();

  @override
  String toString() {
    return r'sonarQubeHotspotsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SonarQubeHotspotsNotifier create() => SonarQubeHotspotsNotifier();

  @override
  bool operator ==(Object other) {
    return other is SonarQubeHotspotsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeHotspotsNotifierHash() =>
    r'11fe8092e0edc7a590977f7265f0a4dde88de596';

/// A project's security hotspots (`US-SQ-HOTSPOT-01`), to review or already
/// reviewed. Read-only: reviewing is `US-SQ-WRITE-04`.

final class SonarQubeHotspotsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SonarQubeHotspotsNotifier,
          AsyncValue<SonarQubeHotspotsState>,
          SonarQubeHotspotsState,
          FutureOr<SonarQubeHotspotsState>,
          String
        > {
  SonarQubeHotspotsNotifierFamily._()
    : super(
        retry: null,
        name: r'sonarQubeHotspotsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A project's security hotspots (`US-SQ-HOTSPOT-01`), to review or already
  /// reviewed. Read-only: reviewing is `US-SQ-WRITE-04`.

  SonarQubeHotspotsNotifierProvider call(String projectKey) =>
      SonarQubeHotspotsNotifierProvider._(argument: projectKey, from: this);

  @override
  String toString() => r'sonarQubeHotspotsNotifierProvider';
}

/// A project's security hotspots (`US-SQ-HOTSPOT-01`), to review or already
/// reviewed. Read-only: reviewing is `US-SQ-WRITE-04`.

abstract class _$SonarQubeHotspotsNotifier
    extends $AsyncNotifier<SonarQubeHotspotsState> {
  late final _$args = ref.$arg as String;
  String get projectKey => _$args;

  FutureOr<SonarQubeHotspotsState> build(String projectKey);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<SonarQubeHotspotsState>, SonarQubeHotspotsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SonarQubeHotspotsState>,
                SonarQubeHotspotsState
              >,
              AsyncValue<SonarQubeHotspotsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// One hotspot's rule name and code (`api/hotspots/show`), loaded when its
/// row is expanded.

@ProviderFor(sonarQubeHotspotDetail)
final sonarQubeHotspotDetailProvider = SonarQubeHotspotDetailFamily._();

/// One hotspot's rule name and code (`api/hotspots/show`), loaded when its
/// row is expanded.

final class SonarQubeHotspotDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SonarQubeHotspotDetail>,
          SonarQubeHotspotDetail,
          FutureOr<SonarQubeHotspotDetail>
        >
    with
        $FutureModifier<SonarQubeHotspotDetail>,
        $FutureProvider<SonarQubeHotspotDetail> {
  /// One hotspot's rule name and code (`api/hotspots/show`), loaded when its
  /// row is expanded.
  SonarQubeHotspotDetailProvider._({
    required SonarQubeHotspotDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sonarQubeHotspotDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeHotspotDetailHash();

  @override
  String toString() {
    return r'sonarQubeHotspotDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SonarQubeHotspotDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SonarQubeHotspotDetail> create(Ref ref) {
    final argument = this.argument as String;
    return sonarQubeHotspotDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SonarQubeHotspotDetailProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sonarQubeHotspotDetailHash() =>
    r'07b0f339c3435d63966a6e89dbccb901a602895c';

/// One hotspot's rule name and code (`api/hotspots/show`), loaded when its
/// row is expanded.

final class SonarQubeHotspotDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SonarQubeHotspotDetail>, String> {
  SonarQubeHotspotDetailFamily._()
    : super(
        retry: null,
        name: r'sonarQubeHotspotDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One hotspot's rule name and code (`api/hotspots/show`), loaded when its
  /// row is expanded.

  SonarQubeHotspotDetailProvider call(String hotspotKey) =>
      SonarQubeHotspotDetailProvider._(argument: hotspotKey, from: this);

  @override
  String toString() => r'sonarQubeHotspotDetailProvider';
}
