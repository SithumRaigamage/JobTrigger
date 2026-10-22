import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/credential/jenkins_server.dart';

part 'credential_dto.freezed.dart';
part 'credential_dto.g.dart';

/// Mirrors `JobTrigger-Backend/models/JenkinsCredential.js` exactly.
@freezed
abstract class CredentialDto with _$CredentialDto {
  const factory CredentialDto({
    @JsonKey(name: '_id') required String id,
    required String serverName,
    required String jenkinsURL,
    required String username,

    /// Null when the backend could not decrypt the stored secret
    /// (AUD-63) — the credential is still listed, but it can't be used
    /// until the user types the secret again.
    String? password,
    String? paramToken,
    @Default(false) bool isDefault,

    /// AUD-63: the backend flags a credential whose secret it could not
    /// decrypt. Always present in the response.
    @Default(false) bool needsReentry,
    String? createdAt,
    String? updatedAt,
  }) = _CredentialDto;

  factory CredentialDto.fromJson(Map<String, dynamic> json) =>
      _$CredentialDtoFromJson(json);
}

extension CredentialDtoX on CredentialDto {
  JenkinsServer toDomain() => JenkinsServer(
    id: id,
    serverName: serverName,
    jenkinsURL: jenkinsURL,
    username: username,
    secret: password,
    paramToken: paramToken,
    isDefault: isDefault,
    // A null secret *is* the unreadable case, so the flag can never
    // disagree with the value it describes.
    needsReentry: needsReentry || password == null,
  );
}
