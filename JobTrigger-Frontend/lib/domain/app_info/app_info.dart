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
    this.releaseNotesUrl,
    this.minSupportedVersion,
  });

  final String appVersion;
  final String buildNumber;
  final String? privacyPolicyUrl;
  final String? termsOfServiceUrl;
  final String? supportEmail;
  final String? openSourceLicensesUrl;

  /// US-PROF-03: the website's changelog.
  final String? releaseNotesUrl;

  /// US-PROF-03: an installed app older than this must update.
  final String? minSupportedVersion;
}

/// US-PROF-03: true when [installed] (e.g. `1.0.0`) is older than
/// [minimum]. Anything unparseable, on either side, blocks nobody: a typo
/// on the server must never lock everyone out.
bool isUpdateRequired(String installed, String? minimum) {
  if (minimum == null) return false;
  final have = _parts(installed);
  final need = _parts(minimum);
  if (have == null || need == null) return false;
  for (var i = 0; i < 3; i++) {
    if (have[i] != need[i]) return have[i] < need[i];
  }
  return false;
}

List<int>? _parts(String version) {
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(version.trim());
  if (match == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
}
