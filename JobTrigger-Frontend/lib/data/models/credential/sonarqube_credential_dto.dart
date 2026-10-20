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
    required String token,
    String? defaultOrganization,
    @Default(false) bool isDefault,
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
  );
}
