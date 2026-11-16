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

  @override
  Future<SubscriptionSnapshot?> cached() async => cachedValue;

  @override
  Future<Result<SubscriptionSnapshot, AppFailure>> load() async {
    loads++;
    return loadResult ?? const Err(NetworkFailure());
  }

  @override
  Future<Result<SubscriptionSnapshot, AppFailure>> refresh() => load();

  @override
  Future<Result<List<BillingOffer>, AppFailure>> offerings() async =>
      const Ok([]);

  @override
  Future<Result<void, AppFailure>> purchase(BillingOffer offer) async =>
      const Ok(null);

  @override
  Future<Result<void, AppFailure>> restore() async => const Ok(null);
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
