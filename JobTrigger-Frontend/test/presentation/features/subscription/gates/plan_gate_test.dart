import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/presentation/features/subscription/billing_availability.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/plan_gate.dart';

import '../../../../support/plan_gates.dart';

void main() {
  group('PlanGate', () {
    test('billing off: nothing is ever blocked', () {
      const gate = PlanGate.open;
      expect(gate.multiTool, isNull);
      expect(gate.backgroundWatch, isNull);
      expect(gate.homeWidget, isNull);
      expect(gate.insights, isNull);
      expect(gate.pinJob(500), isNull);
      expect(gate.addCredential(total: 500, forTool: 500), isNull);
    });

    test('billing off hides a restrictive plan too', () {
      // Billing unavailable (no key, demo): even Free entitlements block
      // nothing.
      final gate = PlanGate(active: false, entitlements: freeGate.entitlements);
      expect(gate.insights, isNull);
      expect(gate.pinJob(99), isNull);
    });

    test('Free blocks each feature with its own reason', () {
      expect(freeGate.multiTool, 'multiTool');
      expect(freeGate.backgroundWatch, 'backgroundWatch');
      expect(freeGate.homeWidget, 'homeWidget');
      expect(freeGate.insights, 'insights');
    });

    test('Free allows 3 pins and blocks the 4th', () {
      expect(freeGate.pinJob(2), isNull);
      expect(freeGate.pinJob(3), 'maxPinnedJobs');
    });

    test('Free allows one server and blocks the second', () {
      expect(freeGate.addCredential(total: 0, forTool: 0), isNull);
      expect(
        freeGate.addCredential(total: 1, forTool: 1),
        'maxCredentialsTotal',
      );
      expect(
        freeGate.credentialLimitFailure('maxCredentialsTotal').message,
        'Your plan allows 1 saved server. Upgrade to Pro to add more.',
      );
    });

    test('a per-tool limit is reported when the total allows more', () {
      const gate = PlanGate(
        active: true,
        entitlements: Entitlements(
          plan: Plan.pro,
          billingEnabled: true,
          limits: PlanLimits(
            maxCredentialsTotal: null,
            maxCredentialsPerTool: 2,
            maxPinnedJobs: null,
          ),
          features: PlanFeatures.all,
        ),
      );
      expect(gate.addCredential(total: 2, forTool: 1), isNull);
      expect(gate.addCredential(total: 2, forTool: 2), 'maxCredentialsPerTool');
    });

    test('Pro blocks nothing', () {
      expect(proGate.multiTool, isNull);
      expect(proGate.insights, isNull);
      expect(proGate.pinJob(100), isNull);
      expect(proGate.addCredential(total: 10, forTool: 10), isNull);
    });
  });

  group('planGateProvider', () {
    test('billing unavailable: open, and the plan is never read', () {
      var planRead = false;
      final c = ProviderContainer(
        overrides: [
          billingAvailableProvider.overrideWithValue(false),
          entitlementsProvider.overrideWith((ref) {
            planRead = true;
            return freeGate.entitlements;
          }),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(planGateProvider).insights, isNull);
      expect(planRead, isFalse);
    });

    test('billing available: follows the entitlements', () {
      final c = ProviderContainer(
        overrides: [
          billingAvailableProvider.overrideWithValue(true),
          entitlementsProvider.overrideWithValue(freeGate.entitlements),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(planGateProvider).insights, 'insights');
    });
  });
}
