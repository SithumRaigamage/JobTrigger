// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_redeem_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PROMO-01: one redemption at a time, never from demo mode.

@ProviderFor(PromoRedeem)
final promoRedeemProvider = PromoRedeemProvider._();

/// US-PROMO-01: one redemption at a time, never from demo mode.
final class PromoRedeemProvider extends $NotifierProvider<PromoRedeem, void> {
  /// US-PROMO-01: one redemption at a time, never from demo mode.
  PromoRedeemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promoRedeemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promoRedeemHash();

  @$internal
  @override
  PromoRedeem create() => PromoRedeem();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$promoRedeemHash() => r'd2a97443b493f89a1000dee20c9f3896437c8f8d';

/// US-PROMO-01: one redemption at a time, never from demo mode.

abstract class _$PromoRedeem extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
