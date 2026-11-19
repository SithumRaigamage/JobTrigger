// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paywall_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// P20-23: loads the store's offers and runs a purchase or restore. After
/// either, asks the backend to re-read the subscription
/// (`POST /api/subscription/refresh`) and hands the answer to
/// [EntitlementsNotifier], so Pro unlocks without waiting for the webhook.

@ProviderFor(PaywallNotifier)
final paywallNotifierProvider = PaywallNotifierProvider._();

/// P20-23: loads the store's offers and runs a purchase or restore. After
/// either, asks the backend to re-read the subscription
/// (`POST /api/subscription/refresh`) and hands the answer to
/// [EntitlementsNotifier], so Pro unlocks without waiting for the webhook.
final class PaywallNotifierProvider
    extends $AsyncNotifierProvider<PaywallNotifier, PaywallState> {
  /// P20-23: loads the store's offers and runs a purchase or restore. After
  /// either, asks the backend to re-read the subscription
  /// (`POST /api/subscription/refresh`) and hands the answer to
  /// [EntitlementsNotifier], so Pro unlocks without waiting for the webhook.
  PaywallNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'paywallNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paywallNotifierHash();

  @$internal
  @override
  PaywallNotifier create() => PaywallNotifier();
}

String _$paywallNotifierHash() => r'cc34c0deb073eb903e56f1e5b085f5051a3804ea';

/// P20-23: loads the store's offers and runs a purchase or restore. After
/// either, asks the backend to re-read the subscription
/// (`POST /api/subscription/refresh`) and hands the answer to
/// [EntitlementsNotifier], so Pro unlocks without waiting for the webhook.

abstract class _$PaywallNotifier extends $AsyncNotifier<PaywallState> {
  FutureOr<PaywallState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PaywallState>, PaywallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PaywallState>, PaywallState>,
              AsyncValue<PaywallState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
