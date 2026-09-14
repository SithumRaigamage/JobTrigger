/// Unified for both a job's `lastBuild` and its `builds[]` history — see
/// `data/models/jenkins/jenkins_build_dto.dart`'s doc comment.
class JenkinsBuild {
  const JenkinsBuild({
    required this.number,
    required this.url,
    this.result,
    required this.timestamp,
    this.duration,
    this.estimatedDuration,
    this.building = false,
    this.displayName,
    this.causes = const [],
  });

  final int number;
  final String url;
  final String?
  result; // SUCCESS | FAILURE | ABORTED | UNSTABLE | null (building)
  final double timestamp; // epoch ms
  final double? duration;
  final double? estimatedDuration;
  final bool building;
  final String? displayName;

  /// Human-readable cause descriptions (US-PIPE-02) — e.g. "Started by
  /// user Jane Doe", "Started by upstream project "foo" build number 12",
  /// "Started by timer". Empty when Jenkins reports none (not requested by
  /// every fetch — see `jenkins_repository_impl.dart`'s `_detailsTree`).
  final List<String> causes;
}
