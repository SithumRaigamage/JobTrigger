import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/build_artifact.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/scm_change.dart';
import '../../../domain/jenkins/upstream_cause.dart';

part 'jenkins_build_dto.freezed.dart';
part 'jenkins_build_dto.g.dart';

/// Unified for both `lastBuild` (on `JenkinsJobDto`) and `builds[]` (job
/// history) — `docs/data-models.md` calls these `BuildSummary`/`JenkinsBuild`
/// in the old app, but the fields are the same shape, so one DTO covers
/// both rather than duplicating.
@freezed
abstract class JenkinsBuildDto with _$JenkinsBuildDto {
  const factory JenkinsBuildDto({
    required int number,
    required String url,
    String? result, // SUCCESS | FAILURE | ABORTED | UNSTABLE | null (building)
    required double timestamp, // epoch ms
    double? duration,
    double? estimatedDuration,
    @Default(false) bool building,
    String? displayName,
    // US-PIPE-02: Jenkins' `actions` array is polymorphic -- only some
    // entries are a `hudson.model.CauseAction` carrying `causes`, and the
    // tree query (`actions[causes[shortDescription]]`) still returns every
    // action entry, just pruned to that one field where present. Flatten
    // straight to the description strings we actually render rather than
    // modeling the full heterogeneous `actions` shape.
    @Default(<String>[])
    @JsonKey(name: 'actions', fromJson: _causesFromJson, includeToJson: false)
    List<String> causes,
    // US-PIPE-09: same source (`actions[causes[...]]`) as `causes` above,
    // pulled out as a second field rather than folded into a richer
    // `causes` element type -- keeps `causes`'s already-shipped shape
    // (`List<String>`) untouched. Both fields target the same JSON key,
    // so both need `includeToJson: false` (this DTO is response-only and
    // never re-encoded anyway).
    @JsonKey(
      name: 'actions',
      fromJson: _upstreamCauseFromJson,
      includeToJson: false,
    )
    UpstreamCause? upstreamCause,
    // US-PIPE-03: `changeSet` is `{"items": [...], "kind": "..."}` — only
    // `items` (each `{msg, author: {fullName}}`) is requested/parsed;
    // `kind` isn't rendered anywhere so it's left off the tree query.
    // `ScmChange` isn't JSON-serializable itself (no toJson) -- fine, since
    // this DTO is response-only and never re-encoded; `includeToJson:
    // false` tells json_serializable not to try.
    @Default(<ScmChange>[])
    @JsonKey(
      name: 'changeSet',
      fromJson: _changesFromJson,
      includeToJson: false,
    )
    List<ScmChange> changes,
    // US-PIPE-07: `artifacts[]` is a flat, non-polymorphic array directly
    // on the build resource -- unlike causes/changes above, no custom
    // unwrapper needed, just a nested DTO.
    @Default(<BuildArtifactDto>[]) List<BuildArtifactDto> artifacts,
    // US-PIPE-08: a third field sourced from `actions` (alongside causes/
    // upstreamCause above) -- this build's *actual recorded* parameter
    // values (`hudson.model.ParametersAction`), distinct from the job's
    // currently-declared defaults (`property[parameterDefinitions[...]]`,
    // already parsed elsewhere for US-JOB-03). Always stringified, same
    // convention as `parameter_form.dart`'s submitted values.
    @Default(<String, String>{})
    @JsonKey(
      name: 'actions',
      fromJson: _parameterValuesFromJson,
      includeToJson: false,
    )
    Map<String, String> parameterValues,
  }) = _JenkinsBuildDto;

  factory JenkinsBuildDto.fromJson(Map<String, dynamic> json) =>
      _$JenkinsBuildDtoFromJson(json);
}

@freezed
abstract class BuildArtifactDto with _$BuildArtifactDto {
  const factory BuildArtifactDto({
    required String fileName,
    required String relativePath,
  }) = _BuildArtifactDto;

  factory BuildArtifactDto.fromJson(Map<String, dynamic> json) =>
      _$BuildArtifactDtoFromJson(json);
}

List<String> _causesFromJson(dynamic rawActions) {
  if (rawActions is! List) return const [];
  final descriptions = <String>[];
  for (final action in rawActions) {
    if (action is! Map<String, dynamic>) continue;
    final causes = action['causes'];
    if (causes is! List) continue;
    for (final cause in causes) {
      if (cause is Map<String, dynamic> &&
          cause['shortDescription'] is String) {
        descriptions.add(cause['shortDescription'] as String);
      }
    }
  }
  return descriptions;
}

UpstreamCause? _upstreamCauseFromJson(dynamic rawActions) {
  if (rawActions is! List) return null;
  for (final action in rawActions) {
    if (action is! Map<String, dynamic>) continue;
    final causes = action['causes'];
    if (causes is! List) continue;
    for (final cause in causes) {
      if (cause is! Map<String, dynamic>) continue;
      final project = cause['upstreamProject'];
      final url = cause['upstreamUrl'];
      if (project is String && url is String) {
        return UpstreamCause(projectName: project, url: url);
      }
    }
  }
  return null;
}

Map<String, String> _parameterValuesFromJson(dynamic rawActions) {
  if (rawActions is! List) return const {};
  final values = <String, String>{};
  for (final action in rawActions) {
    if (action is! Map<String, dynamic>) continue;
    final parameters = action['parameters'];
    if (parameters is! List) continue;
    for (final parameter in parameters) {
      if (parameter is! Map<String, dynamic>) continue;
      final name = parameter['name'];
      final value = parameter['value'];
      if (name is String && value != null) {
        values[name] = value.toString();
      }
    }
  }
  return values;
}

List<ScmChange> _changesFromJson(dynamic rawChangeSet) {
  if (rawChangeSet is! Map<String, dynamic>) return const [];
  final items = rawChangeSet['items'];
  if (items is! List) return const [];
  final changes = <ScmChange>[];
  for (final item in items) {
    if (item is! Map<String, dynamic>) continue;
    final message = item['msg'];
    final author = item['author'];
    final fullName = author is Map<String, dynamic> ? author['fullName'] : null;
    if (message is String && fullName is String) {
      changes.add(ScmChange(author: fullName, message: message));
    }
  }
  return changes;
}

extension JenkinsBuildDtoX on JenkinsBuildDto {
  JenkinsBuild toDomain() => JenkinsBuild(
    number: number,
    url: url,
    result: result,
    timestamp: timestamp,
    duration: duration,
    estimatedDuration: estimatedDuration,
    building: building,
    displayName: displayName,
    causes: causes,
    changes: changes,
    artifacts: artifacts
        .map(
          (a) =>
              BuildArtifact(fileName: a.fileName, relativePath: a.relativePath),
        )
        .toList(),
    upstreamCause: upstreamCause,
    parameterValues: parameterValues,
  );
}
