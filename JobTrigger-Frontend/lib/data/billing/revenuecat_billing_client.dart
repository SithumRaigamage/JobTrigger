import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../domain/subscription/billing_offer.dart';
import 'billing_client.dart';
import 'preview_billing_client.dart';

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
      final period = switch (package.packageType) {
        PackageType.monthly => BillingPeriod.monthly,
        PackageType.annual => BillingPeriod.yearly,
        _ => null,
      };
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
      if (PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw const BillingCancelled();
      }
      throw BillingException('${error.code}: ${error.message}');
    }
  }
}

/// The client for this build: the preview client when the dev-only
/// `BILLING_PREVIEW` flag is set, RevenueCat when the build has a key for
/// the running platform, otherwise [NoBillingClient].
@Riverpod(keepAlive: true)
BillingClient billingClient(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (config.billingPreview) return const PreviewBillingClient();
  final key = config.revenueCatKeyFor(defaultTargetPlatform);
  return key == null ? const NoBillingClient() : RevenueCatBillingClient(key);
}
