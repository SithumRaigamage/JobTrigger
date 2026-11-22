// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_expiry_notice.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PROMO-06: when Pro from a redeemed code ends within three days, that end
/// date; otherwise null. Read from the plan the app already has, so it needs
/// no request.
///
/// This is the reminder's other half, and the one that works for the many
/// people who never allowed notifications: a local notification cannot reach
/// them, so the end of Pro is also said on the screen. No billing-availability
/// gate here — the plan itself already says billing is on and the source is a
/// promo code, and demo mode never has one.

@ProviderFor(promoExpiryNotice)
final promoExpiryNoticeProvider = PromoExpiryNoticeProvider._();

/// US-PROMO-06: when Pro from a redeemed code ends within three days, that end
/// date; otherwise null. Read from the plan the app already has, so it needs
/// no request.
///
/// This is the reminder's other half, and the one that works for the many
/// people who never allowed notifications: a local notification cannot reach
/// them, so the end of Pro is also said on the screen. No billing-availability
/// gate here — the plan itself already says billing is on and the source is a
/// promo code, and demo mode never has one.

final class PromoExpiryNoticeProvider
    extends $FunctionalProvider<DateTime?, DateTime?, DateTime?>
    with $Provider<DateTime?> {
  /// US-PROMO-06: when Pro from a redeemed code ends within three days, that end
  /// date; otherwise null. Read from the plan the app already has, so it needs
  /// no request.
  ///
  /// This is the reminder's other half, and the one that works for the many
  /// people who never allowed notifications: a local notification cannot reach
  /// them, so the end of Pro is also said on the screen. No billing-availability
  /// gate here — the plan itself already says billing is on and the source is a
  /// promo code, and demo mode never has one.
  PromoExpiryNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promoExpiryNoticeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promoExpiryNoticeHash();

  @$internal
  @override
  $ProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime? create(Ref ref) {
    return promoExpiryNotice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$promoExpiryNoticeHash() => r'9d48807a60084331d51a5868ed88e38dcfc8c49d';
