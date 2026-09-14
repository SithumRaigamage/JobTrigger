import 'build_artifact.dart';
import 'scm_change.dart';

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
    this.changes = const [],
    this.artifacts = const [],
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

  /// SCM commits included in this build (US-PIPE-03), most-recent-first as
  /// Jenkins returns them. Empty when Jenkins reports none (not requested
  /// by every fetch — see `_detailsTree`).
  final List<ScmChange> changes;

  /// Files this build produced (US-PIPE-07). Empty when Jenkins reports
  /// none (not requested by every fetch — see `_detailsTree`).
  final List<BuildArtifact> artifacts;

  /// Every non-`url` construction site (`jenkins_url_rewriter.dart`,
  /// `JobDetailNotifier.applyOptimisticCancel`) reconstructed `JenkinsBuild`
  /// field-by-field before this existed, which silently dropped `causes`
  /// (P7-01) until caught and fixed (P7-02) — use this instead of a bare
  /// constructor call whenever only a couple of fields actually change, so
  /// adding a new field here can't quietly go missing at a call site again.
  JenkinsBuild copyWith({
    int? number,
    String? url,
    String? result,
    double? timestamp,
    double? duration,
    double? estimatedDuration,
    bool? building,
    String? displayName,
    List<String>? causes,
    List<ScmChange>? changes,
    List<BuildArtifact>? artifacts,
  }) => JenkinsBuild(
    number: number ?? this.number,
    url: url ?? this.url,
    result: result ?? this.result,
    timestamp: timestamp ?? this.timestamp,
    duration: duration ?? this.duration,
    estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    building: building ?? this.building,
    displayName: displayName ?? this.displayName,
    causes: causes ?? this.causes,
    changes: changes ?? this.changes,
    artifacts: artifacts ?? this.artifacts,
  );
}
