import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/auth/user.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Mirrors the backend's user shape exactly — note the Mongo `_id` key
/// (confirmed against `JobTrigger-Backend/controllers/authController.js`,
/// which responds `{ token, user: { _id, email } }` — the old Swift `User`
/// model's `CodingKeys` maps the same way).
@freezed
abstract class UserDto with _$UserDto {
  const factory UserDto({
    @JsonKey(name: '_id') required String id,
    required String email,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}

extension UserDtoX on UserDto {
  User toDomain() => User(id: id, email: email);
}

/// The signup/login response envelope — `{ token, user }`. Only used inside
/// `AuthRepositoryImpl`; never exposed past the data layer.
@freezed
abstract class AuthResponseDto with _$AuthResponseDto {
  const factory AuthResponseDto({
    required String token,
    required UserDto user,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}
