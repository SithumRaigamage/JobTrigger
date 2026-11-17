import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_tool_link.dart';

part 'sonarqube_tool_links_notifier.g.dart';

/// Which Jenkins jobs and GitHub repositories are linked to which SonarQube
/// project (`US-SQ-XTOOL-01..03`), for the active SonarQube credential.
///
/// **Device only**, in `shared_preferences`: project key and name against a
/// job URL or `owner/name`. No credential of any tool is stored or shared; the
/// card that uses a link calls SonarQube with the SonarQube credential only,
/// and the Jenkins and GitHub screens never see SonarQube's token.
@riverpod
class SonarQubeToolLinksNotifier extends _$SonarQubeToolLinksNotifier {
  static const prefix = 'sonarqube_links_';

  String? _credentialId;

  String get _key => '$prefix$_credentialId';

  @override
  Map<String, SonarQubeToolLink> build() {
    _credentialId = ref.watch(activeSonarQubeCredentialNotifierProvider)?.id;
    if (_credentialId != null) _load();
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || !ref.mounted) return;
      state = {
        for (final entry in (jsonDecode(raw) as Map<String, dynamic>).entries)
          entry.key: SonarQubeToolLink.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      };
    } on Object {
      // Unreadable: start with no links rather than fail a screen.
    }
  }

  SonarQubeToolLink? linkFor(SonarQubeLinkedTool tool, String externalId) =>
      state[sonarQubeLinkId(tool, externalId)];

  Future<void> link(
    SonarQubeLinkedTool tool,
    String externalId,
    SonarQubeProject project,
  ) async {
    state = {
      ...state,
      sonarQubeLinkId(tool, externalId): SonarQubeToolLink(
        projectKey: project.key,
        projectName: project.name,
      ),
    };
    await _save();
  }

  Future<void> unlink(SonarQubeLinkedTool tool, String externalId) async {
    state = {...state}..remove(sonarQubeLinkId(tool, externalId));
    await _save();
  }

  Future<void> _save() async {
    if (_credentialId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({for (final e in state.entries) e.key: e.value.toJson()}),
      );
    } on Object {
      // The link still holds for this session.
    }
  }
}

/// The Jenkins job URLs linked to [projectKey] (`US-SQ-XTOOL-02`): where
/// "Scan now" goes. Usually one, possibly none.
@riverpod
List<String> sonarQubeJenkinsJobsFor(Ref ref, String projectKey) {
  final links = ref.watch(sonarQubeToolLinksNotifierProvider);
  const jenkinsPrefix = 'jenkins|';
  return [
    for (final e in links.entries)
      if (e.key.startsWith(jenkinsPrefix) && e.value.projectKey == projectKey)
        e.key.substring(jenkinsPrefix.length),
  ];
}
