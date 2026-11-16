import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/subscription/subscription_dto.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';

void main() {
  test('parses a Free answer from GET /api/subscription', () {
    final snapshot = SubscriptionDto.fromJson({
      'plan': 'free',
      'billingEnabled': true,
      'status': 'none',
      'source': null,
      'productId': null,
      'periodEnd': null,
      'willRenew': false,
      'manageOnWeb': false,
      'limits': {
        'maxCredentialsTotal': 1,
        'maxCredentialsPerTool': 1,
        'maxPinnedJobs': 3,
      },
      'features': {
        'multiTool': false,
        'backgroundWatch': false,
        'homeWidget': false,
        'insights': false,
      },
      'primaryCredentialId': null,
    }).toDomain();

    expect(snapshot.entitlements.plan, Plan.free);
    expect(snapshot.entitlements.isPro, isFalse);
    expect(snapshot.entitlements.limits.maxPinnedJobs, 3);
    expect(snapshot.entitlements.features.multiTool, isFalse);
    expect(snapshot.status.state, SubscriptionState.none);
    expect(snapshot.status.source, isNull);
  });

  test('parses a web Pro answer; null limits mean unlimited', () {
    final snapshot = SubscriptionDto.fromJson({
      'plan': 'pro',
      'billingEnabled': true,
      'status': 'billing_issue',
      'source': 'web',
      'productId': 'pri_1',
      'periodEnd': '2026-12-01T00:00:00.000Z',
      'willRenew': true,
      'manageOnWeb': true,
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
      'primaryCredentialId': 'abc',
    }).toDomain();

    expect(snapshot.entitlements.isPro, isTrue);
    expect(snapshot.entitlements.limits.maxCredentialsTotal, isNull);
    expect(snapshot.entitlements.features, PlanFeatures.all);
    expect(snapshot.status.state, SubscriptionState.billingIssue);
    expect(snapshot.status.isWeb, isTrue);
    expect(snapshot.status.manageOnWeb, isTrue);
    expect(snapshot.status.willRenew, isTrue);
    expect(snapshot.status.periodEnd, DateTime.utc(2026, 12));
    expect(snapshot.status.primaryCredentialId, 'abc');
  });

  test('an unknown status or source degrades to none / null', () {
    final snapshot = SubscriptionDto.fromJson({
      'plan': 'pro',
      'billingEnabled': false,
      'status': 'something_new',
      'source': 'carrier_pigeon',
      'limits': <String, dynamic>{},
      'features': <String, dynamic>{},
    }).toDomain();
    expect(snapshot.status.state, SubscriptionState.none);
    expect(snapshot.status.source, isNull);
  });
}
