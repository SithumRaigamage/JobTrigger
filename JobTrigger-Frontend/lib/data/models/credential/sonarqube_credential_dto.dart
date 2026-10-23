import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/credential/sonarqube_credential.dart';

part 'sonarqube_credential_dto.freezed.dart';
part 'sonarqube_credential_dto.g.dart';

/// Mirrors `JobTrigger-Backend/models/SonarQubeCredential.js` exactly.
@freezed
abstract class SonarQubeCredentialDto with _$SonarQubeCredentialDto {
  const factory SonarQubeCredentialDto({
    @JsonKey(name: '_id') required String id,
    required String label,
    required String baseUrl,

    /// Null when the backend could not decrypt the stored token (AUD-63)
    /// — the credential is still listed, but it can't be used until the
    /// user types the token again.
    String? token,
    String? defaultOrganization,
    @Default(false) bool isDefault,

    /// AUD-63: the backend flags a credential whose token it could not
    /// decrypt. Always present in the response.
    @Default(false) bool needsReentry,
    String? createdAt,
    String? updatedAt,
  }) = _SonarQubeCredentialDto;

  factory SonarQubeCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$SonarQubeCredentialDtoFromJson(json);
}

extension SonarQubeCredentialDtoX on SonarQubeCredentialDto {
  SonarQubeCredential toDomain() => SonarQubeCredential(
    id: id,
    label: label,
    baseUrl: baseUrl,
    secret: token,
    defaultOrganization: defaultOrganization,
    isDefault: isDefault,
    // A null token *is* the unreadable case, so the flag can never
    // disagree with the value it describes.
    needsReentry: needsReentry || token == null,
  );
}
