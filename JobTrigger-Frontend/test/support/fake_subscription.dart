import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/billing/billing_client.dart';
import 'package:job_trigger/domain/subscription/billing_offer.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/domain/subscription/subscription_repository.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';

/// A Free user with Free's limits (billing on).
const freeSnapshot = SubscriptionSnapshot(
  entitlements: Entitlements(
    plan: Plan.free,
    billingEnabled: true,
    limits: PlanLimits(
      maxCredentialsTotal: 1,
      maxCredentialsPerTool: 1,
      maxPinnedJobs: 3,
    ),
    features: PlanFeatures(
      multiTool: false,
      backgroundWatch: false,
      homeWidget: false,
      insights: false,
    ),
  ),
  status: SubscriptionStatus.none,
);

const proSnapshot = SubscriptionSnapshot(
  entitlements: Entitlements(
    plan: Plan.pro,
    billingEnabled: true,
    limits: PlanLimits(
      maxCredentialsTotal: null,
      maxCredentialsPerTool: 25,
      maxPinnedJobs: null,
    ),
    features: PlanFeatures.all,
  ),
  status: SubscriptionStatus(state: SubscriptionState.active),
);

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({this.cachedValue, this.loadResult});

  SubscriptionSnapshot? cachedValue;
  Result<SubscriptionSnapshot, AppFailure>? loadResult;
  int loads = 0;

  /// What the store sells (Phase 20 PR B).
  Result<List<BillingOffer>, AppFailure> offerResult = const Ok([
    BillingOffer(
      id: 'monthly',
      period: BillingPeriod.monthly,
      priceText: 'LKR 1,200.00',
    ),
    BillingOffer(
      id: 'yearly',
      period: BillingPeriod.yearly,
      priceText: 'LKR 9,900.00',
      trialDays: 7,
    ),
  ]);
  Result<void, AppFailure> purchaseResult = const Ok(null);
  Result<void, AppFailure> restoreResult = const Ok(null);

  /// What `POST /api/subscription/refresh` answers.
  Result<SubscriptionSnapshot, AppFailure>? refreshResult;
  final purchased = <String>[];
  int restores = 0;
  int refreshes = 0;

  /// US-PROMO-01: what `POST /api/subscription/promo` answers, and the codes
  /// it was asked about.
  Result<SubscriptionSnapshot, AppFailure>? promoResult;
  final redeemedCodes = <String>[];

  @override
  Future<Result<SubscriptionSnapshot, AppFailure>> redeemPromoCode(
    String code,
  ) async {
    redeemedCodes.add(code);
    return promoResult ?? const Err(NetworkFailure());
  }

  @override
  Future<SubscriptionSnapshot?> cached() async => cachedValue;

  @override
  Future<Result<SubscriptionSnapshot, AppFailure>> load() async {
    loads++;
    return loadResult ?? const Err(NetworkFailure());
  }

  @override
  Future<Result<SubscriptionSnapshot, AppFailure>> refresh() async {
    refreshes++;
    return refreshResult ?? await load();
  }

  @override
  Future<Result<List<BillingOffer>, AppFailure>> offerings() async =>
      offerResult;

  @override
  Future<Result<void, AppFailure>> purchase(BillingOffer offer) async {
    purchased.add(offer.id);
    return purchaseResult;
  }

  @override
  Future<Result<void, AppFailure>> restore() async {
    restores++;
    return restoreResult;
  }
}

class FakeBillingClient implements BillingClient {
  FakeBillingClient({this.configured = true});

  final bool configured;
  final calls = <String>[];
  Object? purchaseError;

  @override
  bool get isConfigured => configured;

  @override
  Future<void> logIn(String userId) async => calls.add('logIn:$userId');

  @override
  Future<void> logOut() async => calls.add('logOut');

  @override
  Future<List<BillingOffer>> offerings() async => const [
    BillingOffer(
      id: r'$rc_monthly',
      period: BillingPeriod.monthly,
      priceText: 'LKR 1,200.00',
    ),
  ];

  @override
  Future<void> purchase(BillingOffer offer) async {
    if (purchaseError != null) throw purchaseError!;
    calls.add('purchase:${offer.id}');
  }

  @override
  Future<void> restore() async {
    if (purchaseError != null) throw purchaseError!;
    calls.add('restore');
  }
}

/// US-PROMO-01: a Free account whose backend has promo codes to redeem.
final freeWithCodesSnapshot = SubscriptionSnapshot(
  entitlements: freeSnapshot.entitlements,
  status: freeSnapshot.status,
  promoAvailable: true,
);

/// US-PROMO-01: Pro granted by a redeemed code, ending on [end].
SubscriptionSnapshot promoProSnapshot({DateTime? end}) => SubscriptionSnapshot(
  entitlements: proSnapshot.entitlements,
  status: SubscriptionStatus(
    state: SubscriptionState.active,
    source: SubscriptionSource.promo,
    productId: 'LAUNCH30',
    willRenew: false,
    periodEnd: end ?? DateTime.utc(2027, 1, 15, 12),
  ),
  promoAvailable: true,
);

/// Pro bought in a store (App Store), renewing on [end].
SubscriptionSnapshot storeProSnapshot({DateTime? end}) => SubscriptionSnapshot(
  entitlements: proSnapshot.entitlements,
  status: SubscriptionStatus(
    state: SubscriptionState.active,
    source: SubscriptionSource.appStore,
    willRenew: true,
    periodEnd: end ?? DateTime.utc(2027, 1, 15, 12),
  ),
);

/// Pro bought on the website (P20-84).
final webProSnapshot = SubscriptionSnapshot(
  entitlements: proSnapshot.entitlements,
  status: SubscriptionStatus(
    state: SubscriptionState.active,
    source: SubscriptionSource.web,
    willRenew: true,
    manageOnWeb: true,
    periodEnd: DateTime.utc(2027, 1, 15, 12),
  ),
);
