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
}
