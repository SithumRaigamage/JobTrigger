import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/subscription/billing_offer.dart';
import 'billing_client.dart';
import 'preview_billing_client.dart';
import 'sandbox_billing_client.dart';

part 'revenuecat_billing_client.g.dart';

/// P20-20: the only file that imports `purchases_flutter`. The SDK is
/// configured lazily, on the first call that needs it, so a build without
/// a key (or a signed-out session) never starts it.
class RevenueCatBillingClient implements BillingClient {
  RevenueCatBillingClient(this._apiKey);

  final String _apiKey;
  bool _configured = false;
  final Map<String, Package> _packages = {};

  @override
  bool get isConfigured => true;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await Purchases.configure(PurchasesConfiguration(_apiKey));
    _configured = true;
  }

  @override
  Future<void> logIn(String userId) => _guard(() async {
    await _ensureConfigured();
    await Purchases.logIn(userId);
  });

  @override
  Future<void> logOut() => _guard(() async {
    // Nothing to do if the SDK never started (no one was logged in).
    if (!_configured) return;
    if (await Purchases.isAnonymous) return;
    await Purchases.logOut();
  });

  @override
  Future<List<BillingOffer>> offerings() => _guard(() async {
    await _ensureConfigured();
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    _packages.clear();
    if (current == null) return const <BillingOffer>[];
    final offers = <BillingOffer>[];
    for (final package in current.availablePackages) {
      final period = _periodOf(package);
      if (period == null) continue;
      _packages[package.identifier] = package;
      offers.add(
        BillingOffer(
          id: package.identifier,
          period: period,
          priceText: package.storeProduct.priceString,
          trialDays: _trialDays(package.storeProduct.introductoryPrice),
        ),
      );
    }
    return offers;
  });

  @override
  Future<void> purchase(BillingOffer offer) => _guard(() async {
    await _ensureConfigured();
    final package = _packages[offer.id];
    if (package == null) {
      throw const BillingException('That offer is no longer available.');
    }
    await Purchases.purchase(PurchaseParams.package(package));
  });

  @override
  Future<void> restore() => _guard(() async {
    await _ensureConfigured();
    await Purchases.restorePurchases();
  });

  /// Monthly or yearly for [package]. RevenueCat's package *type* is only
  /// right when the package uses one of its predefined identifiers; a
  /// custom package (common on a first Play Console setup) still sells the
  /// same subscription, so fall back to the product's own period and id.
  /// Without that fallback the paywall silently showed no offers.
  static BillingPeriod? _periodOf(Package package) {
    final byType = switch (package.packageType) {
      PackageType.monthly => BillingPeriod.monthly,
      PackageType.annual => BillingPeriod.yearly,
      _ => null,
    };
    if (byType != null) return byType;

    // Play and the App Store report a subscription period like P1M, P1Y.
    final rawPeriod = package.storeProduct.subscriptionPeriod?.toUpperCase();
    if (rawPeriod != null) {
      if (rawPeriod == 'P1Y' || rawPeriod == 'P12M') return BillingPeriod.yearly;
      if (rawPeriod == 'P1M') return BillingPeriod.monthly;
    }

    final id = package.storeProduct.identifier.toLowerCase();
    if (id.contains('year') || id.contains('annual')) return BillingPeriod.yearly;
    if (id.contains('month')) return BillingPeriod.monthly;
    return null;
  }

  /// A free introductory period in days, or null.
  static int? _trialDays(IntroductoryPrice? intro) {
    if (intro == null || intro.price != 0) return null;
    final perUnit = switch (intro.periodUnit) {
      PeriodUnit.day => 1,
      PeriodUnit.week => 7,
      PeriodUnit.month => 30,
      PeriodUnit.year => 365,
      PeriodUnit.unknown => 0,
    };
    final days = perUnit * intro.periodNumberOfUnits * intro.cycles;
    return days > 0 ? days : null;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const BillingCancelled();
      }
      // Play's deferred payment: the SDK can report it either as a result
      // without `pro` or as this error. Both mean "not confirmed yet".
      if (code == PurchasesErrorCode.paymentPendingError) {
        throw const BillingPending();
      }
      throw BillingException('${error.code}: ${error.message}');
    }
  }
}

/// The client for this build: the dev-only sandbox store when
/// `SANDBOX_BILLING` is set, the preview client when `BILLING_PREVIEW` is
/// set, RevenueCat when the build has a key for the running platform,
/// otherwise [NoBillingClient].
@Riverpod(keepAlive: true)
BillingClient billingClient(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (config.billingSandbox) {
    return SandboxBillingClient(ref.watch(dioBackendProvider));
  }
  if (config.billingPreview) return const PreviewBillingClient();
  final key = config.revenueCatKeyFor(defaultTargetPlatform);
  return key == null ? const NoBillingClient() : RevenueCatBillingClient(key);
}
