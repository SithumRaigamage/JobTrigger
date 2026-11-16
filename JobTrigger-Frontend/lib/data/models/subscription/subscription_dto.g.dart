// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionDto _$SubscriptionDtoFromJson(Map<String, dynamic> json) =>
    _SubscriptionDto(
      plan: json['plan'] as String,
      billingEnabled: json['billingEnabled'] as bool,
      status: json['status'] as String,
      limits: PlanLimitsDto.fromJson(json['limits'] as Map<String, dynamic>),
      features: PlanFeaturesDto.fromJson(
        json['features'] as Map<String, dynamic>,
      ),
      source: json['source'] as String?,
      productId: json['productId'] as String?,
      periodEnd: json['periodEnd'] as String?,
      willRenew: json['willRenew'] as bool? ?? false,
      manageOnWeb: json['manageOnWeb'] as bool? ?? false,
      primaryCredentialId: json['primaryCredentialId'] as String?,
    );

Map<String, dynamic> _$SubscriptionDtoToJson(_SubscriptionDto instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'billingEnabled': instance.billingEnabled,
      'status': instance.status,
      'limits': instance.limits,
      'features': instance.features,
      'source': instance.source,
      'productId': instance.productId,
      'periodEnd': instance.periodEnd,
      'willRenew': instance.willRenew,
      'manageOnWeb': instance.manageOnWeb,
      'primaryCredentialId': instance.primaryCredentialId,
    };

_PlanLimitsDto _$PlanLimitsDtoFromJson(Map<String, dynamic> json) =>
    _PlanLimitsDto(
      maxCredentialsTotal: (json['maxCredentialsTotal'] as num?)?.toInt(),
      maxCredentialsPerTool: (json['maxCredentialsPerTool'] as num?)?.toInt(),
      maxPinnedJobs: (json['maxPinnedJobs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlanLimitsDtoToJson(_PlanLimitsDto instance) =>
    <String, dynamic>{
      'maxCredentialsTotal': instance.maxCredentialsTotal,
      'maxCredentialsPerTool': instance.maxCredentialsPerTool,
      'maxPinnedJobs': instance.maxPinnedJobs,
    };

_PlanFeaturesDto _$PlanFeaturesDtoFromJson(Map<String, dynamic> json) =>
    _PlanFeaturesDto(
      multiTool: json['multiTool'] as bool? ?? false,
      backgroundWatch: json['backgroundWatch'] as bool? ?? false,
      homeWidget: json['homeWidget'] as bool? ?? false,
      insights: json['insights'] as bool? ?? false,
    );

Map<String, dynamic> _$PlanFeaturesDtoToJson(_PlanFeaturesDto instance) =>
    <String, dynamic>{
      'multiTool': instance.multiTool,
      'backgroundWatch': instance.backgroundWatch,
      'homeWidget': instance.homeWidget,
      'insights': instance.insights,
    };
