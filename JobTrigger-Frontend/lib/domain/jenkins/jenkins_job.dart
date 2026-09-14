import 'downstream_project.dart';
import 'health_report.dart';
import 'jenkins_build.dart';
import 'job_property.dart';

class JenkinsJob {
  const JenkinsJob({
    required this.name,
    required this.url,
    this.description,
    this.color,
    this.jobs,
    this.lastBuild,
    this.healthReport = const [],
    this.property = const [],
    this.builds = const [],
    this.downstreamProjects = const [],
  });

  final String name;
  final String url;
  final String? description;
  final String? color;
  final List<JenkinsJob>? jobs; // nested folders — null for a leaf job
  final JenkinsBuild? lastBuild;
  final List<HealthReport> healthReport;
  final List<JobProperty> property;
  final List<JenkinsBuild> builds;

  /// Jobs this job triggers (US-PIPE-09). Empty when Jenkins reports none
  /// (not requested by every fetch — see `jenkins_repository_impl.dart`'s
  /// `_detailsTree`).
  final List<DownstreamProject> downstreamProjects;

  /// Ported from `JenkinsServerInfo.swift`'s `JenkinsJob.isFolder`. Depends
  /// on [jobs] staying genuinely `null` (not `[]`) for leaf jobs — see
  /// `data/models/jenkins/jenkins_job_dto.dart`'s doc comment.
  bool get isFolder => jobs != null;

  bool get isParameterized =>
      property.any((prop) => prop.parameterDefinitions != null);
}
