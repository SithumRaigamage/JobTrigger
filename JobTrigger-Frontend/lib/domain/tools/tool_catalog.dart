import 'dart:convert';

/// Which tools this build supports: `release/tools.json`, copied to
/// `config/tools.json` by `scripts/sync-tools.mjs` and bundled as an asset.
/// It is the one answer to "what does this build support" (docs: `release/
/// README.md`). A tool is *released* when its version is at or below
/// [release], compared as numbers.
///
/// Read once at launch (`loadToolCatalog`, in `core/config`); [current] is then a plain value,
/// so `CiTool.isAvailable` stays synchronous. Tests install [allTools]
/// (`test/flutter_test_config.dart`) so tools hidden in a release stay tested.
class ToolCatalog {
  const ToolCatalog({required this.release, required this.versions});

  factory ToolCatalog.fromJson(Map<String, dynamic> json) {
    final tools = json['tools'];
    final release = json['release'];
    if (release is! String || tools is! Map<String, dynamic>) {
      throw const FormatException(
        'config/tools.json is not a release manifest',
      );
    }
    return ToolCatalog(
      release: release,
      versions: {
        for (final entry in tools.entries) entry.key: entry.value as String,
      },
    );
  }

  factory ToolCatalog.parse(String text) =>
      ToolCatalog.fromJson(jsonDecode(text) as Map<String, dynamic>);

  /// The release being built, e.g. `1.0`.
  final String release;

  /// Tool id (a `CiTool` name) to the release it ships in, in manifest order.
  final Map<String, String> versions;

  /// A catalogue with every tool released, for tests.
  static const allTools = ToolCatalog(
    release: '99.0',
    versions: {
      'jenkins': '1.0',
      'sonarqube': '1.1',
      'githubActions': '1.2',
      'gitlab': '1.3',
      'circleci': '1.3',
    },
  );

  /// The catalogue in force. [loadFromAssets] sets it at launch.
  static ToolCatalog current = allTools;

  /// Whether [id] ships in [release] or earlier. An unknown id is not.
  bool isReleased(String id) {
    final version = versions[id];
    return version != null && compareVersions(version, release) <= 0;
  }

  /// The release [id] ships in, or null if the manifest doesn't know it.
  String? versionOf(String id) => versions[id];

  /// The ids not yet released, soonest release first, then manifest order.
  List<String> get comingNext {
    final pending = [
      for (final id in versions.keys)
        if (!isReleased(id)) id,
    ];
    // List.sort isn't stable; pair with the manifest index.
    final order = {for (final (i, id) in versions.keys.indexed) id: i};
    pending.sort((a, b) {
      final byVersion = compareVersions(versions[a]!, versions[b]!);
      return byVersion != 0 ? byVersion : order[a]!.compareTo(order[b]!);
    });
    return pending;
  }

  /// `1.10` is after `1.2`: numbers, not text.
  static int compareVersions(String a, String b) {
    final left = a.split('.').map(int.parse).toList();
    final right = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 2; i++) {
      final difference = left[i] - right[i];
      if (difference != 0) return difference;
    }
    return 0;
  }
}
