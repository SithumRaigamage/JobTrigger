import 'downstream_project.dart';
import 'health_report.dart';
import 'jenkins_build.dart';
import 'job_property.dart';
import 'parameter_definition.dart';

class JenkinsJob {
  const JenkinsJob({
    required this.name,
    required this.url,
    this.jobClass,
    this.displayName,
    this.description,
    this.color,
    this.buildable,
    this.jobs,
    this.lastBuild,
    this.lastSuccessfulBuild,
    this.lastFailedBuild,
    this.healthReport = const [],
    this.property = const [],
    this.builds = const [],
    this.downstreamProjects = const [],
  });

  /// Container classes that hold jobs but can't be built themselves. A
  /// folder is recognised by its class even when its `jobs` weren't fetched
  /// (lazy loading, or the recursive crawl's depth limit — AUD-19).
  static const folderClasses = {
    'com.cloudbees.hudson.plugins.folder.Folder',
    'org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject',
    'jenkins.branch.OrganizationFolder',
  };

  /// URL-safe item name, e.g. `feature%2Flogin` for a multibranch branch.
  final String name;
  final String url;

  /// Jenkins' `_class`, e.g. `hudson.model.FreeStyleProject`. Null in
  /// hand-built navigation stubs (upstream/downstream links).
  final String? jobClass;

  /// Human name, e.g. `feature/login`. Prefer [label] for display.
  final String? displayName;
  final String? description;
  final String? color;

  /// `false` for a disabled job. Null when not requested.
  final bool? buildable;
  final List<JenkinsJob>? jobs; // nested folders — null for a leaf job
  final JenkinsBuild? lastBuild;

  /// US-JX-05. Only fetched by the job detail query; null elsewhere.
  final JenkinsBuild? lastSuccessfulBuild;
  final JenkinsBuild? lastFailedBuild;
  final List<HealthReport> healthReport;
  final List<JobProperty> property;
  final List<JenkinsBuild> builds;

  /// Jobs this job triggers (US-PIPE-09). Empty when Jenkins reports none
  /// (not requested by every fetch — see `jenkins_repository_impl.dart`'s
  /// `_detailsTree`).
  final List<DownstreamProject> downstreamProjects;

  /// Ported from `JenkinsServerInfo.swift`'s `JenkinsJob.isFolder`, now
  /// also true for a known folder class whose children weren't fetched.
  /// Still depends on [jobs] staying genuinely `null` (not `[]`) for leaf
  /// jobs — see `data/models/jenkins/jenkins_job_dto.dart`'s doc comment.
  bool get isFolder => jobs != null || folderClasses.contains(jobClass);

  static const multibranchClass =
      'org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject';
  static const organizationFolderClass = 'jenkins.branch.OrganizationFolder';

  /// A multibranch pipeline project (US-JX-03).
  bool get isMultibranch => jobClass == multibranchClass;

  /// A project that can be re-scanned for branches/repositories — a
  /// multibranch project or an organization folder (US-JX-03).
  bool get isScannable =>
      jobClass == multibranchClass || jobClass == organizationFolderClass;

  /// What to show the user: `displayName`, else the URL-decoded [name]
  /// (`feature%2Flogin` → `feature/login`), else [name] as-is.
  String get label {
    final display = displayName;
    if (display != null && display.isNotEmpty) return display;
    try {
      return Uri.decodeComponent(name);
    } on ArgumentError {
      return name;
    }
  }

  bool get isParameterized =>
      property.any((prop) => prop.parameterDefinitions != null);

  /// Every parameter the job declares, flattened across its properties.
  List<ParameterDefinition> get parameterDefinitions => [
    for (final prop in property) ...?prop.parameterDefinitions,
  ];

  JenkinsJob copyWith({
    String? url,
    List<JenkinsJob>? jobs,
    JenkinsBuild? lastBuild,
    JenkinsBuild? lastSuccessfulBuild,
    JenkinsBuild? lastFailedBuild,
    List<JenkinsBuild>? builds,
    List<DownstreamProject>? downstreamProjects,
  }) => JenkinsJob(
    name: name,
    url: url ?? this.url,
    jobClass: jobClass,
    displayName: displayName,
    description: description,
    color: color,
    buildable: buildable,
    jobs: jobs ?? this.jobs,
    lastBuild: lastBuild ?? this.lastBuild,
    lastSuccessfulBuild: lastSuccessfulBuild ?? this.lastSuccessfulBuild,
    lastFailedBuild: lastFailedBuild ?? this.lastFailedBuild,
    healthReport: healthReport,
    property: property,
    builds: builds ?? this.builds,
    downstreamProjects: downstreamProjects ?? this.downstreamProjects,
  );
}
