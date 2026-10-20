// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_credential_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SonarQubeCredentialDto _$SonarQubeCredentialDtoFromJson(
  Map<String, dynamic> json,
) => _SonarQubeCredentialDto(
  id: json['_id'] as String,
  label: json['label'] as String,
  baseUrl: json['baseUrl'] as String,
  token: json['token'] as String,
  defaultOrganization: json['defaultOrganization'] as String?,
  isDefault: json['isDefault'] as bool? ?? false,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$SonarQubeCredentialDtoToJson(
  _SonarQubeCredentialDto instance,
) => <String, dynamic>{
  '_id': instance.id,
  'label': instance.label,
  'baseUrl': instance.baseUrl,
  'token': instance.token,
  'defaultOrganization': instance.defaultOrganization,
  'isDefault': instance.isDefault,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
