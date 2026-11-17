/// Pure domain entity — mirrors the old Swift app's `AppInfo` model. `id`,
/// `createdAt`/`updatedAt` are storage bookkeeping only and deliberately not
/// carried into the domain layer (nothing in the UI needs them).
class AppInfo {
  const AppInfo({
    required this.appVersion,
    required this.buildNumber,
    this.privacyPolicyUrl,
    this.termsOfServiceUrl,
    this.supportEmail,
    this.openSourceLicensesUrl,
  });

  final String appVersion;
  final String buildNumber;
  final String? privacyPolicyUrl;
  final String? termsOfServiceUrl;
  final String? supportEmail;
  final String? openSourceLicensesUrl;
}
