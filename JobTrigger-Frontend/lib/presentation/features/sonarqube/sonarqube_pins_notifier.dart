import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';

part 'sonarqube_pins_notifier.g.dart';

/// A pinned project (`US-SQ-PIN-01`): key and name only, both non-secret
/// (`CLAUDE.md` §7), so `shared_preferences` is the right store. The name is
/// kept so the home-screen widget and the offline list can show the project
/// without asking the server.
class PinnedSonarQubeProject {
  const PinnedSonarQubeProject({required this.key, required this.name});

  factory PinnedSonarQubeProject.fromJson(Map<String, dynamic> json) =>
      PinnedSonarQubeProject(
        key: json['key'] as String,
        name: json['name'] as String,
      );

  final String key;
  final String name;

  Map<String, String> toJson() => {'key': key, 'name': name};
}

/// Pins for the active SonarQube credential, in the order pinned. Pins
/// belong to a credential — a different server has different projects — so
/// the list is rebuilt and reloaded whenever the credential changes. Local
/// only: SonarQube's own server-side favourites (`api/favorites`) would be a
/// write and are `US-SQ-WRITE-*` territory.
@riverpod
class SonarQubePinsNotifier extends _$SonarQubePinsNotifier {
  static const prefix = 'sonarqube_pins_';

  String? _credentialId;

  String get _key => '$prefix$_credentialId';

  @override
  List<PinnedSonarQubeProject> build() {
    _credentialId = ref.watch(activeSonarQubeCredentialNotifierProvider)?.id;
    if (_credentialId != null) _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || !ref.mounted) return;
      state = [
        for (final item in jsonDecode(raw) as List<dynamic>)
          PinnedSonarQubeProject.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      // Unreadable or corrupt: start with no pins rather than fail a screen.
    }
  }

  bool isPinned(String projectKey) => state.any((p) => p.key == projectKey);

  /// Pins [project], or unpins it when already pinned. Returns true if it
  /// is now pinned.
  Future<bool> toggle(SonarQubeProject project) async {
    final pinned = isPinned(project.key);
    state = pinned
        ? [
            for (final pin in state)
              if (pin.key != project.key) pin,
          ]
        : [
            ...state,
            PinnedSonarQubeProject(key: project.key, name: project.name),
          ];
    await _save();
    return !pinned;
  }

  Future<void> _save() async {
    if (_credentialId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([for (final pin in state) pin.toJson()]),
      );
    } on Object {
      // The pin still holds for this session.
    }
  }
}

/// The pinned keys alone, for sorting and for the pin buttons.
@riverpod
Set<String> sonarQubePinnedKeys(Ref ref) => {
  for (final pin in ref.watch(sonarQubePinsNotifierProvider)) pin.key,
};

/// A pin button's tooltip and semantics label, one place so it reads the same
/// on the card and the project page.
String sonarQubePinLabel({required bool pinned, required String name}) =>
    pinned ? 'Unpin $name' : 'Pin $name';
