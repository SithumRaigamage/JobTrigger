import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/billing/billing_client.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/subscription/billing_offer.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_subscription.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final Object body;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _proBody = {
  'plan': 'pro',
  'billingEnabled': true,
  'status': 'active',
  'source': 'app_store',
  'willRenew': true,
  'limits': {
    'maxCredentialsTotal': null,
    'maxCredentialsPerTool': 25,
    'maxPinnedJobs': null,
  },
  'features': {
    'multiTool': true,
    'backgroundWatch': true,
    'homeWidget': true,
    'insights': true,
  },
};

SubscriptionRepositoryImpl _repo(_Adapter adapter, BillingClient billing) =>
    SubscriptionRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://backend.test'))
        ..httpClientAdapter = adapter,
      billing,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('load reads GET /api/subscription and caches the body', () async {
    final adapter = _Adapter(200, _proBody);
    final repo = _repo(adapter, FakeBillingClient());

    expect(await repo.cached(), isNull);
    final result = await repo.load();

    expect(adapter.paths, ['GET /api/subscription']);
    expect((result as Ok).value.entitlements.plan, Plan.pro);
    expect((await repo.cached())!.entitlements.plan, Plan.pro);
  });

  test('refresh posts to /api/subscription/refresh', () async {
    final adapter = _Adapter(200, _proBody);
    await _repo(adapter, FakeBillingClient()).refresh();
    expect(adapter.paths, ['POST /api/subscription/refresh']);
  });

  test(
    'a failed load maps to an AppFailure and leaves the cache alone',
    () async {
      final good = _repo(_Adapter(200, _proBody), FakeBillingClient());
      await good.load();

      final result = await _repo(
        _Adapter(500, {'message': 'x'}),
        FakeBillingClient(),
      ).load();

      expect((result as Err).error, isA<ServerFailure>());
      expect((await good.cached())!.entitlements.plan, Plan.pro);
    },
  );

  test(
    'a body that is not the expected shape is an UnexpectedResponse',
    () async {
      final result = await _repo(
        _Adapter(200, {'unexpected': true}),
        FakeBillingClient(),
      ).load();
      expect((result as Err).error, isA<UnexpectedResponseFailure>());
    },
  );

  test('a cancelled store sheet is PurchaseCancelled; other store errors are '
      'StoreFailure', () async {
    final billing = FakeBillingClient();
    final repo = _repo(_Adapter(200, _proBody), billing);
    const offer = BillingOffer(
      id: r'$rc_annual',
      period: BillingPeriod.yearly,
      priceText: 'x',
    );

    billing.purchaseError = const BillingCancelled();
    expect(
      ((await repo.purchase(offer)) as Err).error,
      isA<PurchaseCancelled>(),
    );

    billing.purchaseError = const BillingException('boom');
    expect(((await repo.restore()) as Err).error, isA<StoreFailure>());

    // Play's deferred payment is not a failure: the paywall checks the plan
    // and reports it as pending instead of claiming Pro.
    billing.purchaseError = const BillingPending();
    expect(await repo.purchase(offer), isA<Ok<void, AppFailure>>());

    billing.purchaseError = null;
    expect(await repo.purchase(offer), isA<Ok<void, AppFailure>>());
    expect(billing.calls, [r'purchase:$rc_annual']);
  });

  test('a build with no billing offers nothing and cannot purchase', () async {
    final repo = _repo(_Adapter(200, _proBody), const NoBillingClient());
    expect(((await repo.offerings()) as Ok).value, isEmpty);
    expect(await repo.restore(), isA<Err<void, AppFailure>>());
  });
}
