import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/app_info/app_info.dart';

part 'app_info_dto.freezed.dart';
part 'app_info_dto.g.dart';

/// Mirrors `JobTrigger-Backend/models/AppInfo.js` exactly.
@freezed
abstract class AppInfoDto with _$AppInfoDto {
  const factory AppInfoDto({
    @JsonKey(name: '_id') required String id,
    required String appVersion,
    required String buildNumber,
    String? privacyPolicyUrl,
    String? termsOfServiceUrl,
    String? supportEmail,
    String? openSourceLicensesUrl,
    String? createdAt,
    String? updatedAt,
  }) = _AppInfoDto;

  factory AppInfoDto.fromJson(Map<String, dynamic> json) =>
      _$AppInfoDtoFromJson(json);
}

extension AppInfoDtoX on AppInfoDto {
  AppInfo toDomain() => AppInfo(
    appVersion: appVersion,
    buildNumber: buildNumber,
    privacyPolicyUrl: usableLink(privacyPolicyUrl),
    termsOfServiceUrl: usableLink(termsOfServiceUrl),
    supportEmail: supportEmail,
    openSourceLicensesUrl: usableLink(openSourceLicensesUrl),
  );
}

/// PE-05: a link the About screen can open, or null so the row is hidden.
/// Drops anything that isn't http(s) and the reserved placeholder domains
/// (`example.com/.org/.net`, RFC 2606) an unconfigured backend still
/// returns, so a user never lands on a dead page.
String? usableLink(String? url) {
  final uri = url == null ? null : Uri.tryParse(url.trim());
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return null;
  }
  const placeholders = {'example.com', 'example.org', 'example.net'};
  final host = uri.host.toLowerCase();
  if (host.isEmpty ||
      placeholders.any((p) => host == p || host.endsWith('.$p'))) {
    return null;
  }
  return url!.trim();
}
