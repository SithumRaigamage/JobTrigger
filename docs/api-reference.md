# API Reference

Two distinct APIs, two distinct `Dio` clients, two distinct auth schemes.
Never share an interceptor or base URL between them.

## 1. Backend API (`lab-trigger-backend`, JWT bearer)

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
| `/api/appinfo` | GET | Public | — | `AppInfo` | Cache with a short TTL; not worth polling |

`BackendApiClient` interceptor: attach a plain `x-auth-token: <token>`
header from secure storage on every request except signup/login/appinfo;
on `401`, clear stored session and route to login (see `auth_notifier.dart`).
**Not** `Authorization: Bearer` — verified directly against
`lab-trigger-backend/middleware/auth.js`, which only reads
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
| `{baseURL}/api/json?tree=jobs[name,url,color,jobs[name,url,color,jobs[...]]]` | GET | Recursive job/folder tree | Depth-limit the `tree` query at 6 levels to match the original app; going deeper risks huge payloads on large Jenkins instances |
| `{jobURL}api/json?tree={detailsTree}` | GET | Job detail: params, health, recent builds | `detailsTree` includes `property[parameterDefinitions[*]],healthReport[*],lastBuild[*],builds[number,url,result,timestamp,duration,building]` |
| `{jobURL}build` | POST | Trigger build, no params | |
| `{jobURL}buildWithParameters` | POST | Trigger build with params | Body: `application/x-www-form-urlencoded`, all values stringified |
| `{jobURL}{buildNumber}/stop` | POST | Cancel a running build | Optimistically flip local state to `ABORTED` before the next poll confirms it |
| `{buildURL}logText/progressiveText?start={offset}` | GET | Incremental console log | Read `X-Text-Size` (next offset) and `X-More-Data` (bool) response headers; stop polling when `X-More-Data` is absent/false |

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
