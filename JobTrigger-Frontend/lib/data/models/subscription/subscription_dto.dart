import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/subscription/entitlements.dart';
import '../../../domain/subscription/subscription_status.dart';

part 'subscription_dto.freezed.dart';
part 'subscription_dto.g.dart';

/// Mirrors the body of `GET /api/subscription` (`docs/api-reference.md`).
@freezed
abstract class SubscriptionDto with _$SubscriptionDto {
  const factory SubscriptionDto({
    required String plan,
    required bool billingEnabled,
    required String status,
    required PlanLimitsDto limits,
    required PlanFeaturesDto features,
    String? source,
    String? productId,
    String? periodEnd,
    @Default(false) bool willRenew,
    @Default(false) bool manageOnWeb,
    String? primaryCredentialId,
  }) = _SubscriptionDto;

  factory SubscriptionDto.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDtoFromJson(json);
}

@freezed
abstract class PlanLimitsDto with _$PlanLimitsDto {
  const factory PlanLimitsDto({
    int? maxCredentialsTotal,
    int? maxCredentialsPerTool,
    int? maxPinnedJobs,
  }) = _PlanLimitsDto;

  factory PlanLimitsDto.fromJson(Map<String, dynamic> json) =>
      _$PlanLimitsDtoFromJson(json);
}

@freezed
abstract class PlanFeaturesDto with _$PlanFeaturesDto {
  const factory PlanFeaturesDto({
    @Default(false) bool multiTool,
    @Default(false) bool backgroundWatch,
    @Default(false) bool homeWidget,
    @Default(false) bool insights,
  }) = _PlanFeaturesDto;

  factory PlanFeaturesDto.fromJson(Map<String, dynamic> json) =>
      _$PlanFeaturesDtoFromJson(json);
}

extension SubscriptionDtoX on SubscriptionDto {
  SubscriptionSnapshot toDomain() => SubscriptionSnapshot(
    entitlements: Entitlements(
      plan: plan == 'pro' ? Plan.pro : Plan.free,
      billingEnabled: billingEnabled,
      limits: PlanLimits(
        maxCredentialsTotal: limits.maxCredentialsTotal,
        maxCredentialsPerTool: limits.maxCredentialsPerTool,
        maxPinnedJobs: limits.maxPinnedJobs,
      ),
      features: PlanFeatures(
        multiTool: features.multiTool,
        backgroundWatch: features.backgroundWatch,
        homeWidget: features.homeWidget,
        insights: features.insights,
      ),
    ),
    status: SubscriptionStatus(
      state: _stateOf(status),
      source: _sourceOf(source),
      productId: productId,
      periodEnd: periodEnd == null ? null : DateTime.tryParse(periodEnd!),
      willRenew: willRenew,
      manageOnWeb: manageOnWeb,
      primaryCredentialId: primaryCredentialId,
    ),
  );
}

SubscriptionState _stateOf(String value) => switch (value) {
  'trialing' => SubscriptionState.trialing,
  'active' => SubscriptionState.active,
  'grace' => SubscriptionState.grace,
  'billing_issue' => SubscriptionState.billingIssue,
  'cancelled' => SubscriptionState.cancelled,
  'expired' => SubscriptionState.expired,
  _ => SubscriptionState.none,
};

SubscriptionSource? _sourceOf(String? value) => switch (value) {
  'app_store' => SubscriptionSource.appStore,
  'play_store' => SubscriptionSource.playStore,
  'web' => SubscriptionSource.web,
  'promo' => SubscriptionSource.promo,
  'admin' => SubscriptionSource.admin,
  'student' => SubscriptionSource.student,
  _ => null,
};
