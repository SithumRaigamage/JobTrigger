// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppInfoDto _$AppInfoDtoFromJson(Map<String, dynamic> json) => _AppInfoDto(
  id: json['_id'] as String,
  appVersion: json['appVersion'] as String,
  buildNumber: json['buildNumber'] as String,
  privacyPolicyUrl: json['privacyPolicyUrl'] as String?,
  termsOfServiceUrl: json['termsOfServiceUrl'] as String?,
  supportEmail: json['supportEmail'] as String?,
  openSourceLicensesUrl: json['openSourceLicensesUrl'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$AppInfoDtoToJson(_AppInfoDto instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'appVersion': instance.appVersion,
      'buildNumber': instance.buildNumber,
      'privacyPolicyUrl': instance.privacyPolicyUrl,
      'termsOfServiceUrl': instance.termsOfServiceUrl,
      'supportEmail': instance.supportEmail,
      'openSourceLicensesUrl': instance.openSourceLicensesUrl,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
