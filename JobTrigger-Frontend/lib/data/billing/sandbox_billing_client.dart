import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/subscription/billing_offer.dart';
import '../../domain/subscription/sandbox_billing.dart';
import 'billing_client.dart';

/// Development-only store simulator. It charges nothing and never contacts
/// Apple, Google or RevenueCat: it asks the local backend's sandbox
/// endpoints to write the same store source a real purchase would, so the
/// whole flow (buy → cancel → expire → resubscribe) can be exercised before
/// the store accounts exist.
///
/// Only ever constructed when `AppConfig.billingSandbox` is set, which no
/// release build can be. The backend also refuses the endpoints in
/// production.
class SandboxBillingClient implements BillingClient, SandboxBilling {
  SandboxBillingClient(this._dio);

  final Dio _dio;

  // The prices the plans are sold at; a sandbox has no store-localised
  // strings to ask for. Mirrors JobTrigger-Web/src/content/pricing.ts.
  static const _monthly = BillingOffer(
    id: 'sandbox_monthly',
    period: BillingPeriod.monthly,
    priceText: '\$9.99',
  );
  static const _yearly = BillingOffer(
    id: 'sandbox_yearly',
    period: BillingPeriod.yearly,
    priceText: '\$29.99',
    trialDays: 7,
  );

  @override
  bool get isConfigured => true;

  @override
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {}

  @override
  Future<List<BillingOffer>> offerings() async => const [_monthly, _yearly];

  @override
  Future<void> purchase(BillingOffer offer) => _post(
    '/api/billing/sandbox/purchase',
    {
      'period': offer.period == BillingPeriod.yearly ? 'yearly' : 'monthly',
      'platform': defaultTargetPlatform == TargetPlatform.iOS
          ? 'app_store'
          : 'play_store',
    },
  );

  /// Nothing to restore in a sandbox: the backend already has the plan, and
  /// the screen refreshes it.
  @override
  Future<void> restore() async {}

  @override
  Future<void> cancelSubscription() =>
      _post('/api/billing/sandbox/cancel', null);

  @override
  Future<void> resubscribe() =>
      _post('/api/billing/sandbox/resubscribe', null);

  @override
  Future<void> expireNow() => _post('/api/billing/sandbox/expire', null);

  Future<void> _post(String path, Map<String, Object>? body) async {
    try {
      await _dio.post<Map<String, dynamic>>(path, data: body);
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message'] : null;
      throw BillingException(
        message is String
            ? message
            : 'Sandbox request failed (${error.response?.statusCode ?? error.type.name}).',
      );
    }
  }
}
