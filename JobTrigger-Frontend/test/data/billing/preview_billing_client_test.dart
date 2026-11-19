import 'package:flutter_test/flutter_test.dart';

import 'package:job_trigger/data/billing/billing_client.dart';
import 'package:job_trigger/data/billing/preview_billing_client.dart';
import 'package:job_trigger/domain/subscription/billing_offer.dart';

void main() {
  const client = PreviewBillingClient();

  test('is configured, so the subscription UI opens', () {
    expect(client.isConfigured, isTrue);
  });

  test('serves the website\'s two plans as static offers', () async {
    final offers = await client.offerings();

    expect(offers.map((o) => o.period), [
      BillingPeriod.monthly,
      BillingPeriod.yearly,
    ]);
    expect(offers.map((o) => o.priceText), [r'$9.99', r'$29.99']);
    expect(offers.last.trialDays, 7);
  });

  test('never takes money: a purchase fails with a store-less message', () {
    expect(
      () => client.purchase(
        const BillingOffer(
          id: 'preview_monthly',
          period: BillingPeriod.monthly,
          priceText: r'$9.99',
        ),
      ),
      throwsA(
        isA<BillingException>().having(
          (e) => e.debugMessage,
          'debugMessage',
          contains('no store'),
        ),
      ),
    );
  });

  test('restore completes and finds nothing', () async {
    await expectLater(client.restore(), completes);
  });

  test('identity calls are no-ops', () async {
    await expectLater(client.logIn('u1'), completes);
    await expectLater(client.logOut(), completes);
  });
}
