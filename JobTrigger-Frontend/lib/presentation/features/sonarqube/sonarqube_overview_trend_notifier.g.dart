// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_overview_trend_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Compares the loaded Overview with the snapshots this device kept, and
/// saves this visit as the next one. Only a fully loaded Overview counts: a
/// half-loaded one would look like a sudden improvement.

@ProviderFor(SonarQubeOverviewTrendNotifier)
final sonarQubeOverviewTrendNotifierProvider =
    SonarQubeOverviewTrendNotifierProvider._();

/// Compares the loaded Overview with the snapshots this device kept, and
/// saves this visit as the next one. Only a fully loaded Overview counts: a
/// half-loaded one would look like a sudden improvement.
final class SonarQubeOverviewTrendNotifierProvider
    extends
        $NotifierProvider<SonarQubeOverviewTrendNotifier, SonarQubeTrendState> {
  /// Compares the loaded Overview with the snapshots this device kept, and
  /// saves this visit as the next one. Only a fully loaded Overview counts: a
  /// half-loaded one would look like a sudden improvement.
  SonarQubeOverviewTrendNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeOverviewTrendNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeOverviewTrendNotifierHash();

  @$internal
  @override
  SonarQubeOverviewTrendNotifier create() => SonarQubeOverviewTrendNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeTrendState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeTrendState>(value),
    );
  }
}

String _$sonarQubeOverviewTrendNotifierHash() =>
    r'b62221bfd5905bd7d60852744cc11b4a07244fee';

/// Compares the loaded Overview with the snapshots this device kept, and
/// saves this visit as the next one. Only a fully loaded Overview counts: a
/// half-loaded one would look like a sudden improvement.

abstract class _$SonarQubeOverviewTrendNotifier
    extends $Notifier<SonarQubeTrendState> {
  SonarQubeTrendState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SonarQubeTrendState, SonarQubeTrendState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SonarQubeTrendState, SonarQubeTrendState>,
              SonarQubeTrendState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
