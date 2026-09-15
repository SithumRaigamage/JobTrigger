import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/credential/github_credential.dart';

part 'github_credential_dto.freezed.dart';
part 'github_credential_dto.g.dart';

/// Mirrors `JobTrigger-Backend/models/GitHubCredential.js` exactly.
@freezed
abstract class GitHubCredentialDto with _$GitHubCredentialDto {
  const factory GitHubCredentialDto({
    @JsonKey(name: '_id') required String id,
    required String label,
    required String token,
    String? defaultOwner,
    @Default(false) bool isDefault,
    String? createdAt,
    String? updatedAt,
  }) = _GitHubCredentialDto;

  factory GitHubCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubCredentialDtoFromJson(json);
}

extension GitHubCredentialDtoX on GitHubCredentialDto {
  GitHubCredential toDomain() => GitHubCredential(
    id: id,
    label: label,
    secret: token,
    defaultOwner: defaultOwner,
    isDefault: isDefault,
  );
}
