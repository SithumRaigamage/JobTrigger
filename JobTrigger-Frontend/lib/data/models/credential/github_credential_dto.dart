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

    /// Null when the backend could not decrypt the stored token (AUD-63)
    /// — the credential is still listed, but it can't be used until the
    /// user types the token again.
    String? token,
    String? defaultOwner,
    @Default(false) bool isDefault,

    /// AUD-63: the backend flags a credential whose token it could not
    /// decrypt. Always present in the response.
    @Default(false) bool needsReentry,
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
    // A null token *is* the unreadable case, so the flag can never
    // disagree with the value it describes.
    needsReentry: needsReentry || token == null,
  );
}
