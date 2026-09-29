# API Reference

Two distinct APIs, two distinct `Dio` clients, two distinct auth schemes.
Never share an interceptor or base URL between them.

## 1. Backend API (`JobTrigger-Backend`, JWT bearer)

Base URL from `core/config/app_config.dart`, e.g. `https://api.jobtrigger.app`
(configurable per build flavor — dev/staging/prod).

| Endpoint | Method | Auth | Request body | Response | Notes |
|---|---|---|---|---|---|
| `/api/auth/signup` | POST | Public | `{ email, password }` | `{ user, token }` | Client-side validate email regex + min password length before sending |
| `/api/auth/login` | POST | Public | `{ email, password }` | `{ user, token }` | On success, store token in secure storage immediately |
| `/api/credentials` | GET | `x-auth-token` | — | `Credential[]` | |
| `/api/credentials` | POST | `x-auth-token` | `Credential` (minus id) | `Credential` | |
| `/api/credentials/:id` | PUT | `x-auth-token` | Partial `Credential` | `Credential` | |
| `/api/credentials/:id` | DELETE | `x-auth-token` | — | `{ success }` | If deleting the active server, client must fall back to another `isDefault`/first server |
| `/api/credentials/switch/:id` | POST | `x-auth-token` | — | `Credential` | Backend flips `isDefault`; client also updates `ActiveServerNotifier` locally for instant UI feedback |
| `/api/sonarqube-credentials` | GET | `x-auth-token` | — | `SonarQubeCredential[]` | |
| `/api/sonarqube-credentials` | POST | `x-auth-token` | `SonarQubeCredential` (minus id) | `SonarQubeCredential` | |
| `/api/sonarqube-credentials/:id` | PUT | `x-auth-token` | Partial `SonarQubeCredential` | `SonarQubeCredential` | |
| `/api/sonarqube-credentials/:id` | DELETE | `x-auth-token` | — | `{ message }` | |
| `/api/sonarqube-credentials/switch/:id` | POST | `x-auth-token` | — | `SonarQubeCredential` | Backend flips `isDefault`; client also updates `ActiveSonarQubeCredentialNotifier` locally for instant UI feedback |
| `/api/appinfo` | GET | Public | — | `AppInfo` | Cache with a short TTL; not worth polling |

`BackendApiClient` interceptor: attach a plain `x-auth-token: <token>`
header from secure storage on every request except signup/login/appinfo;
on `401`, clear stored session and route to login (see `auth_notifier.dart`).
**Not** `Authorization: Bearer` — verified directly against
`JobTrigger-Backend/middleware/auth.js`, which only reads
`req.header('x-auth-token')`. This doc previously said `Bearer`, which never
matched the real backend and made every authenticated request 401 silently
(discovered only once the Flutter client was exercised end-to-end against a
real running backend, not just tested with mocked Dio adapters).

## 2. Jenkins API (direct, per-server Basic Auth)

Base URL = active `Credential.jenkinsURL`. A new `Dio` instance (via
`JenkinsClientFactory`) is created whenever the active server changes, with
`Authorization: Basic base64(username:password)` set once at construction —
Jenkins credentials are not JWTs and don't rotate mid-session.

| Endpoint pattern | Method | Purpose | Notes |
|---|---|---|---|
| `{baseURL}/api/json` | GET | Connection health check | Used by "test connection" in server add/edit flow; surface job count or the raw HTTP status on failure |
| `{baseURL}/api/json?tree=jobs[name,url,color,jobs[name,url,color,jobs[...]]]` | GET | Recursive job/folder tree | Depth-limit the `tree` query at 6 levels to match the original app; going deeper risks huge payloads on large Jenkins instances. **Note (AUD-19):** the code currently builds 5 levels, not 6. Phase 11 replaces this with lazy per-folder loading (see below) |
| `{jobURL}api/json?tree={detailsTree}` | GET | Job detail: params, health, recent builds | `detailsTree` includes `property[parameterDefinitions[*]],healthReport[*],lastBuild[*],builds[number,url,result,timestamp,duration,building]` |
| `{jobURL}build` | POST | Trigger build, no params | |
| `{jobURL}buildWithParameters` | POST | Trigger build with params | Body: `application/x-www-form-urlencoded`, all values stringified. **A blank password parameter is omitted**, because an explicit `''` overrides the stored secret (US-JX-01). A duplicate of an already-queued identical build returns **303** with that queue item as `Location`, which counts as success (AUD-37). An empty Run parameter returns **500** (AUD-38) |
| `{jobURL}{buildNumber}/stop` | POST | Cancel a running build | Optimistically flip local state to `ABORTED` before the next poll confirms it |
| `{buildURL}logText/progressiveText?start={offset}` | GET | Incremental console log | Read `X-Text-Size` (next offset) and `X-More-Data` (bool) response headers; stop polling when `X-More-Data` is absent/false |

### Epic PIPE endpoints (implemented, Phase 7)

| Endpoint pattern | Method | Purpose | Notes |
|---|---|---|---|
| `{baseURL}/crumbIssuer/api/json` | GET | CSRF crumb (`NFR-SEC-06`) | Fetched lazily by the client interceptor on the first POST. A 404 means no crumb issuer |
| `{queueItemURL}api/json` | GET | Track a triggered build's queue item (US-PIPE-01) | Queue-item URL comes from the trigger response's `Location` header |
| `{buildURL}testReport/api/json` | GET | Test summary (US-PIPE-06) | A 404 means no report, which is a normal state |
| `{buildURL}artifact/{relativePath}` | GET | Artifact bytes (US-PIPE-07) | Each path segment is percent-encoded |
| `{buildURL}wfapi/describe` | GET | Pipeline stages (US-PIPE-04) | A 404 means not a pipeline |
| `{buildURL}wfapi/pendingInputActions` | GET | Paused input step (US-PIPE-05) | A 404 or empty list means nothing is paused. Each input's parameters are `{name, type, description, definition: {defaultVal, choices}}`, which is **not** the job-parameter shape |
| `{buildURL}input/{id}/proceedEmpty` · `proceed` · `abort` | POST | Approve or reject an input step | `proceed` takes the Stapler form field `json={"parameter":[{"name":…,"value":…}]}`, because plain `name=value` fields get a 400. Permission denied is a **400** HTML page ("You need to have Job/Build permissions…"), mapped to `AuthFailure`. An already-handled input returns 404. Verified in P11-02 |

### Epic JX endpoints (Phase 11, planned)

Each row's status changes from *planned* to *implemented* in the same change
that ships its task. Response shapes are **provisional** until verified
against the fixture Jenkins (P11-02, `NFR-TEST-02`).

| Endpoint pattern | Method | Story | Status |
|---|---|---|---|
| `{folderURL}api/json?tree=jobs[_class,name,displayName,url,color,buildable,lastBuild[…]]` | GET | Lazy per-folder tree (AUD-19/20), US-JX-03 | planned |
| `{multibranchURL}api/json?tree=views[name,jobs[url]]` | GET | US-JX-03 branch/PR/tag grouping | planned |
| `{multibranchURL}build?delay=0` | POST | US-JX-03 scan repository now | planned |
| `{multibranchURL}indexing/api/json` · `indexing/consoleText` | GET | US-JX-03 scan status and log | planned |
| `{buildURL}execution/node/{id}/wfapi/describe` | GET | US-JX-04 stage steps | planned |
| `{buildURL}execution/node/{id}/wfapi/log` | GET | US-JX-04 step log (`text`, `hasMore`) | planned |
| `{jobURL}api/json?tree=lastSuccessfulBuild[…],lastFailedBuild[…],lastStableBuild[…]` | GET | US-JX-05 | planned |
| `{jobURL}api/json?tree=allBuilds[…]{start,end}` | GET | US-JX-06 paging | planned |
| `{buildURL}consoleText` | GET | US-JX-07 full-log download and earlier lines | planned |
| `{buildURL}timestamps/?time=HH:mm:ss&appendLog` | GET | US-JX-07 timestamps (Timestamper plugin; a 404 hides the toggle) | planned |
| `{buildURL}testReport/api/json?tree=suites[cases[…,errorDetails,errorStackTrace,age]{0,200}]` | GET | US-JX-08 | planned |
| `{baseURL}/queue/api/json?tree=items[…]` | GET | US-JX-09 server queue | planned |
| `{baseURL}/queue/cancelItem?id={id}` | POST | US-JX-09 cancel queued item | planned |
| `{baseURL}/computer/api/json?tree=computer[…]` | GET | US-JX-12 nodes and executors | planned |
| `{baseURL}/computer/{name}/toggleOffline?offlineMessage=…` | POST | US-JX-12 (`(built-in)` for the controller) | planned |
| `{jobURL}enable` · `{jobURL}disable` | POST | US-JX-13 | planned |
| `{buildURL}toggleLogKeep` | POST | US-JX-14 keep forever | planned |
| `{buildURL}submitDescription` (form `description`) | POST | US-JX-14 | planned |
| `{buildURL}replay/run` (form `mainScript` + Stapler `json`) | POST | US-JX-16, verification-gated | planned |
| `{baseURL}/api/json?tree=views[name,url],primaryView[name]` · `{viewURL}api/json` | GET | US-JX-17 views | planned |
| `{baseURL}/api/json?tree=quietingDown,mode` + `X-Jenkins` header | GET | US-JX-18 server status | planned |
| `{jobURL}buildWithParameters` as `multipart/form-data` | POST | US-JX-02 file parameters | planned |

Every POST above goes through the shared Jenkins client, so it gets the CSRF
crumb and session cookie automatically. A 403 on an admin-flavoured action
(scan, node toggle, enable/disable, replay) is shown as a *permission*
message, not "credentials rejected" (see US-JX-12).

### URL rewriting

Every `url` field in Jenkins JSON responses is rewritten to match the
active `jenkinsURL`'s scheme/host/port before being stored in domain
entities — see `docs/architecture.md#5-jenkins-url-normalization`. Do this
rewrite in the repository layer, once, not ad hoc at each call site.

### Polling intervals (match original app unless a task says otherwise)

- Job detail "is it still building": every 5s while `lastBuild.building == true`.
- Build log progressive streaming: as fast as responses return (no fixed
  delay needed beyond avoiding a tight loop — ~1s between reads is
  reasonable if the server responds quickly).

### Error shapes to handle explicitly

- `401`/`403` from Jenkins → `AuthFailure` → prompt to re-check credentials
  for that server (not the global app session — Jenkins auth is per-server).
- Connection refused / timeout → `NetworkFailure` → shown as "can't reach
  server", with a retry action.
- Any other non-2xx → `ServerFailure(statusCode)` → generic message with
  the status code visible for debugging.
