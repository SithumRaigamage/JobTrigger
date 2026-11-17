/// Which other tool a SonarQube project is linked to (`US-SQ-XTOOL-*`).
enum SonarQubeLinkedTool { jenkins, github }

/// A Jenkins job or GitHub repository tied to a SonarQube project. Kept on
/// the device only (`US-SQ-XTOOL-01`): the key and name of the project and
/// nothing of either tool's credentials.
class SonarQubeToolLink {
  const SonarQubeToolLink({
    required this.projectKey,
    required this.projectName,
  });

  factory SonarQubeToolLink.fromJson(Map<String, dynamic> json) =>
      SonarQubeToolLink(
        projectKey: json['key'] as String,
        projectName: json['name'] as String,
      );

  final String projectKey;
  final String projectName;

  Map<String, String> toJson() => {'key': projectKey, 'name': projectName};
}

/// The map key for a linked item: the tool and its own id (a Jenkins job's
/// URL, a GitHub repository's `owner/name`).
String sonarQubeLinkId(SonarQubeLinkedTool tool, String externalId) =>
    '${tool.name}|$externalId';

/// The job a Jenkins build URL belongs to:
/// `https://ci/job/team/job/api/42/` → `https://ci/job/team/job/api/`.
/// A URL that does not end in a build number is returned as given (with a
/// trailing slash), so a job URL maps to itself.
String jenkinsJobUrlFromBuildUrl(String buildUrl) {
  final withSlash = buildUrl.endsWith('/') ? buildUrl : '$buildUrl/';
  final match = RegExp(r'^(.*/)\d+/$').firstMatch(withSlash);
  return match?.group(1) ?? withSlash;
}
