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
    privacyPolicyUrl: privacyPolicyUrl,
    termsOfServiceUrl: termsOfServiceUrl,
    supportEmail: supportEmail,
    openSourceLicensesUrl: openSourceLicensesUrl,
  );
}
