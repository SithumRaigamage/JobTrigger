// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_consent_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Profile → "Share anonymous usage" (P20-76). Not a secret, so
/// `shared_preferences`, like the theme. [UmamiAnalyticsService] reads the
/// same key at send time, so turning it off stops the very next event.

@ProviderFor(AnalyticsConsentNotifier)
final analyticsConsentNotifierProvider = AnalyticsConsentNotifierProvider._();

/// Profile → "Share anonymous usage" (P20-76). Not a secret, so
/// `shared_preferences`, like the theme. [UmamiAnalyticsService] reads the
/// same key at send time, so turning it off stops the very next event.
final class AnalyticsConsentNotifierProvider
    extends $AsyncNotifierProvider<AnalyticsConsentNotifier, bool> {
  /// Profile → "Share anonymous usage" (P20-76). Not a secret, so
  /// `shared_preferences`, like the theme. [UmamiAnalyticsService] reads the
  /// same key at send time, so turning it off stops the very next event.
  AnalyticsConsentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsConsentNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsConsentNotifierHash();

  @$internal
  @override
  AnalyticsConsentNotifier create() => AnalyticsConsentNotifier();
}

String _$analyticsConsentNotifierHash() =>
    r'a97ec93b714c121ef09c28155509766e0f0b1642';

/// Profile → "Share anonymous usage" (P20-76). Not a secret, so
/// `shared_preferences`, like the theme. [UmamiAnalyticsService] reads the
/// same key at send time, so turning it off stops the very next event.

abstract class _$AnalyticsConsentNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
