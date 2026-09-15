// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CredentialDto _$CredentialDtoFromJson(Map<String, dynamic> json) =>
    _CredentialDto(
      id: json['_id'] as String,
      serverName: json['serverName'] as String,
      jenkinsURL: json['jenkinsURL'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      paramToken: json['paramToken'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$CredentialDtoToJson(_CredentialDto instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'serverName': instance.serverName,
      'jenkinsURL': instance.jenkinsURL,
      'username': instance.username,
      'password': instance.password,
      'paramToken': instance.paramToken,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
