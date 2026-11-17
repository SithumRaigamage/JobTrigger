import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/config/app_config.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/billing_availability.dart';

import '../../../support/fake_subscription.dart';

AppConfig _config({bool billingPreview = false}) => AppConfig(
  environment: AppEnvironment.dev,
  backendBaseUrl: 'http://127.0.0.1:5001',
  billingPreview: billingPreview,
);

void main() {
  test('BILLING_PREVIEW opens the subscription UI without keys', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config(billingPreview: true)),
        billingClientProvider.overrideWithValue(
          FakeBillingClient(configured: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(billingAvailableProvider), isTrue);
  });

  test('demo mode still wins over the preview flag', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config(billingPreview: true)),
        demoModeInitialProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(billingAvailableProvider), isFalse);
  });

  test('no flag and no SDK key is still off', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config()),
        billingClientProvider.overrideWithValue(
          FakeBillingClient(configured: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(billingAvailableProvider), isFalse);
  });
}
