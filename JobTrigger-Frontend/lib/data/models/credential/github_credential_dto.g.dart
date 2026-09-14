// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_credential_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubCredentialDto _$GitHubCredentialDtoFromJson(Map<String, dynamic> json) =>
    _GitHubCredentialDto(
      id: json['_id'] as String,
      label: json['label'] as String,
      token: json['token'] as String,
      defaultOwner: json['defaultOwner'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$GitHubCredentialDtoToJson(
  _GitHubCredentialDto instance,
) => <String, dynamic>{
  '_id': instance.id,
  'label': instance.label,
  'token': instance.token,
  'defaultOwner': instance.defaultOwner,
  'isDefault': instance.isDefault,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
