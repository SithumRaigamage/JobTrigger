# Data Models — Old → New Mapping

Convention: DTOs live in `data/models/`, mirror raw JSON exactly (including
Jenkins' inconsistent nullability), and expose a `toDomain()` method. Domain
entities live in `domain/` and are what notifiers/widgets actually use.

## User / Auth

Old: `User.swift`, `User.js` (Mongoose)

```dart
// data/models/auth/user_dto.dart
@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String email,
    String? token,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
}

// domain/auth/user.dart
class User {
  final String id;
  final String email;
  const User({required this.id, required this.email});
}
```
JWT is not kept on the domain entity — it lives only in secure storage,
attached to requests by the Dio interceptor.

## Jenkins Credential

Old: `JenkinsCredentials.swift`, `JenkinsCredential.js`

```dart
@freezed
class CredentialDto with _$CredentialDto {
  const factory CredentialDto({
    @JsonKey(name: '_id') required String id,
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String password,
    String? paramToken,
    @Default(false) bool isDefault,
    String? createdAt,
    String? updatedAt,
  }) = _CredentialDto;

  factory CredentialDto.fromJson(Map<String, dynamic> json) => _$CredentialDtoFromJson(json);
}
```
Domain `JenkinsServer` entity drops the raw `password` field name in favor
of `secret` to make clear at call sites it's sensitive, and is never logged
(add a custom `toString()` override that redacts it).

## Jenkins Server Info / Job Tree

Old: `JenkinsServerInfo.swift`

```dart
@freezed
class JenkinsServerInfoDto with _$JenkinsServerInfoDto {
  const factory JenkinsServerInfoDto({
    String? mode,
    String? nodeDescription,
    int? numExecutors,
    bool? useSecurity,
    @Default([]) List<JenkinsJobDto> jobs,
  }) = _JenkinsServerInfoDto;

  factory JenkinsServerInfoDto.fromJson(Map<String, dynamic> json) =>
      _$JenkinsServerInfoDtoFromJson(json);
}

@freezed
class JenkinsJobDto with _$JenkinsJobDto {
  const factory JenkinsJobDto({
    required String name,
    required String url,
    String? description,
    String? color,
    @Default([]) List<JenkinsJobDto>? jobs,       // nested folders
    BuildSummaryDto? lastBuild,
    @Default([]) List<HealthReportDto>? healthReport,
    @Default([]) List<JobPropertyDto>? property,   // holds parameterDefinitions
    @Default([]) List<JenkinsBuildDto>? builds,
  }) = _JenkinsJobDto;

  factory JenkinsJobDto.fromJson(Map<String, dynamic> json) =>
      _$JenkinsJobDtoFromJson(json);
}
```

`jobs` recursing into itself is exactly what supports the 6-level folder
depth from the tree-query endpoint; the recursive `fromJson` "just works"
with `json_serializable`'s generated code, no manual recursion needed.

## Build Summary / Build

Old: `BuildSummary`, `JenkinsBuild`

```dart
@freezed
class JenkinsBuildDto with _$JenkinsBuildDto {
  const factory JenkinsBuildDto({
    required int number,
    required String url,
    String? result,           // SUCCESS | FAILURE | ABORTED | UNSTABLE | null(building)
    required double timestamp,      // epoch ms
    double? duration,
    double? estimatedDuration,
    @Default(false) bool building,
    String? displayName,
  }) = _JenkinsBuildDto;

  factory JenkinsBuildDto.fromJson(Map<String, dynamic> json) =>
      _$JenkinsBuildDtoFromJson(json);
}
```

Domain-side computed helper (not on the DTO): `BuildProgress.ratioFor(build)`
→ `(DateTime.now().millisecondsSinceEpoch - build.timestamp) / build.estimatedDuration`,
clamped to `[0, 1]`, used by the progress bar. Keep this pure function in
`domain/jenkins/build_progress.dart` so it's unit-testable without widgets.

## Parameter Definition (polymorphic default value)

Old: `ParameterDefinition` with a hand-rolled `JSONValue` union for
`defaultValue` (Jenkins returns it as string, bool, or number depending on
parameter type).

```dart
@freezed
class ParameterDefinitionDto with _$ParameterDefinitionDto {
  const factory ParameterDefinitionDto({
    required String name,
    required String type,          // StringParameterDefinition | ChoiceParameterDefinition | BooleanParameterDefinition
    String? description,
    List<String>? choices,
    @JsonKey(fromJson: _defaultValueFromJson) dynamic defaultValue,
  }) = _ParameterDefinitionDto;

  factory ParameterDefinitionDto.fromJson(Map<String, dynamic> json) =>
      _$ParameterDefinitionDtoFromJson(json);
}

dynamic _defaultValueFromJson(dynamic raw) {
  // Jenkins nests it as {"name": "...", "value": <actual default>}
  if (raw is Map<String, dynamic>) return raw['value'];
  return raw;
}
```
The parameter **form** (Phase 5) switches on `type` to render a text field,
dropdown, or switch, and always serializes the submitted value back to a
`String` for the `x-www-form-urlencoded` body — Jenkins' trigger endpoints
expect strings regardless of the declared parameter type.

## Health Report / Job Property

Straightforward 1:1 DTOs (`HealthReportDto { description, iconClassName,
score }`, `JobPropertyDto { parameterDefinitions }`) — no special handling
needed, included here only so the tree stays complete for `fromJson` codegen.

## App Info

Old: `AppInfo` model + `/api/appinfo`. Kept as-is: `AppInfoDto { version,
build, minSupportedVersion, releaseNotesUrl }` — used by
`presentation/features/app_info` to gate forced-update prompts if the
backend ever returns a `minSupportedVersion` above the running app version.
