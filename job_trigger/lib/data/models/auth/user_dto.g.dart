// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) =>
    _UserDto(id: json['_id'] as String, email: json['email'] as String);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  '_id': instance.id,
  'email': instance.email,
};

_AuthResponseDto _$AuthResponseDtoFromJson(Map<String, dynamic> json) =>
    _AuthResponseDto(
      token: json['token'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseDtoToJson(_AuthResponseDto instance) =>
    <String, dynamic>{'token': instance.token, 'user': instance.user};
