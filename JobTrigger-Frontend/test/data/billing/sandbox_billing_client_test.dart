import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/billing/billing_client.dart';
import 'package:job_trigger/data/billing/sandbox_billing_client.dart';
import 'package:job_trigger/domain/subscription/billing_offer.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <(String, Object?)>[];
  int status = 200;
  String message = 'Nope';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((options.uri.path, options.data));
    return ResponseBody.fromString(
      jsonEncode(status == 200 ? {} : {'message': message}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SandboxBillingClient _client(_Adapter adapter) => SandboxBillingClient(
  Dio(BaseOptions(baseUrl: 'https://backend.test'))
    ..httpClientAdapter = adapter,
);

void main() {
  test('sells the two plans locally, without a store', () async {
    final adapter = _Adapter();
    final offers = await _client(adapter).offerings();

    expect(offers.map((o) => o.period), [
      BillingPeriod.monthly,
      BillingPeriod.yearly,
    ]);
    expect(offers.first.priceText, r'$9.99');
    expect(offers.last.priceText, r'$29.99');
    expect(offers.last.trialDays, 7);
    expect(adapter.requests, isEmpty);
  });

  test('a yearly purchase asks the backend sandbox for a yearly plan', () async {
    final adapter = _Adapter();
    final client = _client(adapter);
    final offers = await client.offerings();

    await client.purchase(offers.last);

    final (path, body) = adapter.requests.single;
    expect(path, '/api/billing/sandbox/purchase');
    expect(body, containsPair('period', 'yearly'));
    expect(
      body,
      containsPair('platform', anyOf('play_store', 'app_store')),
    );
  });

  test('cancel, resubscribe and expire each call their own route', () async {
    final adapter = _Adapter();
    final client = _client(adapter);

    await client.cancelSubscription();
    await client.resubscribe();
    await client.expireNow();

    expect(adapter.requests.map((r) => r.$1), [
      '/api/billing/sandbox/cancel',
      '/api/billing/sandbox/resubscribe',
      '/api/billing/sandbox/expire',
    ]);
    expect(adapter.requests.every((r) => r.$2 == null), isTrue);
  });

  test('a refusal is a BillingException, never a raw DioException', () async {
    final adapter = _Adapter()
      ..status = 409
      ..message = 'There is no sandbox subscription to cancel.';
    final client = _client(adapter);

    await expectLater(
      client.cancelSubscription(),
      throwsA(
        isA<BillingException>().having(
          (e) => e.debugMessage,
          'debugMessage',
          'There is no sandbox subscription to cancel.',
        ),
      ),
    );
  });
}
