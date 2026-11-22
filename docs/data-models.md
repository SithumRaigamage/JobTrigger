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

## SonarQube Credential

New — no SwiftUI equivalent, see epic SQ
(`docs/user-stories/sonarqube/14-sonarqube.md`). Backend:
`JobTrigger-Backend/models/SonarQubeCredential.js`.

```dart
@freezed
class SonarQubeCredentialDto with _$SonarQubeCredentialDto {
  const factory SonarQubeCredentialDto({
    @JsonKey(name: '_id') required String id,
    required String label,
    required String baseUrl,
    required String token,
    String? defaultOrganization,
    @Default(false) bool isDefault,
    String? createdAt,
    String? updatedAt,
  }) = _SonarQubeCredentialDto;

  factory SonarQubeCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$SonarQubeCredentialDtoFromJson(json);
}
```
Domain `SonarQubeCredential` entity renames `token` to `secret`, same
sensitive-field convention as `JenkinsServer`/`GitHubCredential`, and is
never logged (redacted `toString()`). `baseUrl` defaults to
`https://sonarcloud.io` but is editable for a self-hosted SonarQube Server
instance — unlike `GitHubCredential`, which has no configurable base URL at
all (GitHub Actions is cloud-only in this app's current scope).

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

## Phase 11 entities (Jenkins extended, no SwiftUI equivalent)

These are small, flat shapes. `JenkinsRepositoryImpl` builds them straight
from the `tree`-limited JSON inside its guarded closures (see
`architecture.md` §6), so they have no separate `@freezed` DTO. A
malformed field becomes `UnexpectedResponseFailure`, never a crash.

| Entity (`lib/domain/…`) | Fields | Story |
|---|---|---|
| `jenkins/queue_entry.dart` `QueueEntry` | `id`, `taskName`, `taskUrl`, `why`, `inQueueSince`, `stuck`, `blocked`, `taskColor` | US-JX-09 queue |
| `jenkins/server_status.dart` `ServerStatus` | `version` (from the `X-Jenkins` header), `quietingDown` | US-JX-18 |
| `jenkins/jenkins_node.dart` `JenkinsNode` / `RunningExecutable` | `displayName`, `isBuiltIn`, `offline`, `temporarilyOffline`, `offlineReason`, `numExecutors`, `running`, disk free and warning bytes | US-JX-12 |
| `jenkins/jenkins_view.dart` `JenkinsView` | `name`, `url`, `isPrimary` | US-JX-17 |
| `jenkins/build_trends.dart` `BuildTrends` / `TrendPoint` | `sampleSize`, `successRate`, `averageMillis`, `points` (number, duration, failed); computed from the history already fetched | US-JX-15 |
| `jenkins/history_filter.dart` `HistoryFilter` | `result` (`HistoryResultFilter`), `startedByMe` | US-JX-06 |
| `jenkins/log_chunk.dart` `LogChunk` | `text`, `nextOffset`, `hasMoreData` (progressive-text headers) | US-JX-07 console |
| `jenkins/parameter_file.dart` `ParameterFile` | `fileName`, `path`, `sizeBytes`; a picked local file, streamed as multipart and never copied | US-JX-02 |
| `jenkins/branch_kind.dart` `BranchKind` | branch / PR / tag, with `sectionTitle` | US-JX-03 |
| `jenkins/build_watch.dart` `BuildWatch` / `BuildNotification` | `serverId`, `jobUrl`, `jobLabel`, `buildNumber` (null means every build), `lastNotified`; JSON in `shared_preferences` | US-JX-10 |
| `app_lock/app_lock_settings.dart` `AppLockSettings` | `enabled`, `timeout`, `requireForSensitive`; `shared_preferences` | US-JX-21 |
| `widget/widget_snapshot.dart` `WidgetSnapshot` / `WidgetJob` | jobs (`label`, `link`, `status`, `statusText`, `buildNumber`, `buildTimestamp`), `updatedAt`; handed to the native widgets | US-JX-23 |

Everything persisted outside secure storage here (watches, lock settings,
and the widget snapshot) holds only names, URLs, numbers, and settings,
never a credential (`CLAUDE.md` §7).

## App Info

Old: `AppInfo` model + `/api/appinfo`. Kept as-is: `AppInfoDto { version,
build, minSupportedVersion, releaseNotesUrl }` — used by
`presentation/features/app_info` to gate forced-update prompts if the
backend ever returns a `minSupportedVersion` above the running app version.

Built 2026-11-21 (US-PROF-03): the backend `AppInfo` document has
`releaseNotesUrl` (seeded as `<SITE_URL>/changelog`) and
`minSupportedVersion` (seeded from `MIN_SUPPORTED_APP_VERSION`, `null`
when unset). The app's `AppInfo` carries both; `isUpdateRequired`
(`domain/app_info/app_info.dart`) compares `x.y.z` versions, and anything
unparseable blocks nobody. `UpdateRequiredGate` covers the app when the
installed version is older. An existing production document gets the new
fields only when `scripts/seedAppInfo.js` is run again.

## Student plan (Phase 21, backend)

- `Subscription.student` — a fourth Pro source beside `store`, `web` and `grant`: `{ plan: "pro", status: "active", source: "student", startsAt, periodEnd }`. A paid source always wins over it (`billing/combine.js`); when the date passes, `isPro` is false, so expiry is computed on every read and never depends on a job.
- `Subscription.promo` — US-PROMO-01: a fifth source, a redeemed promo or voucher code: `{ plan: "pro", status: "active", source: "promo", productId: <the code>, startsAt, periodEnd }`. Ranked with the student year, so anything paid or granted always outranks it; expiry is computed from `periodEnd` on every read, like the student year. `productId` holds the code so the owner console shows which one was used.
- `PromoRedemption` — `{ code, userId, days, periodEnd }` with a unique `{ code, userId }` index (one redemption per account per code) and a `{ code }` index for counting. The codes themselves live in `PROMO_CODES` (config, never the database); this collection only records who used each one, and is deleted with the account.
- `User.role` — `user` (default) or `superAdmin`. Set only by `scripts/grant-role.js` on a local database; no API reads or writes it.
- `StudentVerification` — one application: `method` (`email`|`document`), `status` (`pending`|`approved`|`rejected`|`expired`), `universityEmail`, the pending code as a salted hash with `codeExpiresAt` and `codeAttempts`, `emailVerifiedAt` (US-STU-01: the right code was entered; the application still waits for a super admin), the document (encrypted, never in JSON), decision fields and the granted `approvedAt`..`expiresAt`. Deleted with the account.
- `StudentClaim` — `{ kind: "email"|"document", hash }` with a unique index. SHA-256 only, no user id, kept after the account or application is deleted so one university email or document can claim only once.
- Config: `STUDENT_ADMIN_EMAIL` (who is told about each application), `STUDENT_RENEWAL_ENABLED` (default `false`), `config/studentDomains.json` (owner-editable domain list).
- Document path (PR 2): `StudentVerification.fullName` (as on the ID) and the encrypted `documentData` live only until `documentDeleteAt` (30 days after the decision); then the daily job (`lib/studentJobs.js`, or `node scripts/run-student-jobs.js`) clears both and sets `documentDeletedAt`. `documentHash`, `documentMime`, `documentSize` and the `StudentClaim` stay.
- App (Phase 21): `lib/domain/student/` (`StudentApplication`, document checks), `StudentRepository` (backend calls; a refusal with the backend's own words is a `StudentRequestFailure`, which carries the `code`), `StudentFlowNotifier` (email → code, or document), `StudentStatusNotifier`. `SubscriptionSource.student` shows as "Pro (Student)" with the end date.
- Daily job (`lib/studentJobs.js`, also `node scripts/run-student-jobs.js`): deletes decided documents after 30 days, emails the account address once in the last 7 days of a year (`reminderSentAt`), and marks ended years `expired` with the plan back to Free. Who has Pro is always decided by the date, so a missed run changes nothing about access. The app's banner reads the end date from the plan it already has (`SubscriptionSnapshot.studentYearEndingSoon`).

## Support ticket (Phase 25, backend)

- `SupportTicket` (`models/SupportTicket.js`) — `userId`, `category` (`bug` |
  `feature` | `question` | `tool_request`), `subject` (≤120), `message`
  (≤4000), `replyEmail`, diagnostics (`appVersion`, `buildNumber`, `tool`,
  `platform`, `serverHost` = scheme+host+port only), `status` (`open` |
  `triaged` | `closed`) and timestamps. Deleted with the account.
- Content is scrubbed before it is stored, with the same rules as crash
  reports (`docs/error-reporting.md`): no token, password, `Basic`/`Bearer`
  value or MongoDB URI survives, and a URL keeps only its host.
- App side: `lib/domain/support/` (`SupportTicket`, `SupportCategory`,
  `SupportDiagnostics`, `hostOnly`), `SupportRepository`,
  `SupportFormNotifier` (one submission) and `MySupportTicketsNotifier`.
  `SupportCategory.wire` is the backend enum, so the app and the model never
  drift.

