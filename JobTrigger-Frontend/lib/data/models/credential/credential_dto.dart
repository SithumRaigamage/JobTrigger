import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/credential/jenkins_server.dart';

part 'credential_dto.freezed.dart';
part 'credential_dto.g.dart';

/// Mirrors `lab-trigger-backend/models/JenkinsCredential.js` exactly.
@freezed
abstract class CredentialDto with _$CredentialDto {
  const factory CredentialDto({
    @JsonKey(name: '_id') required String id,
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String password,
    String? paramToken,
    @Default(false) bool isDefault,
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
  );
}
