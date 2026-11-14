# Crash and error reporting (Phase Emergency, E3)

The backend, the website and the app report unexpected errors to a
self-hosted **GlitchTip** (Sentry-compatible), one project each:
`jobtrigger-backend`, `jobtrigger-web`, `jobtrigger-app`. The SDKs are
`@sentry/node`, `@sentry/nextjs` and `sentry_flutter`. Decisions: `tasks/phase-emergency.md`
(PE-00, E3).

## What is sent

Errors only: the exception, its stack trace, the release (`<version>` for
backend and web, `<version>+<build>` for the app) and the environment
(`development` | `staging` | `production`). Performance tracing is off. Nothing
else is collected: no breadcrumbs, screenshots, view hierarchy, session
replay or user feedback.

The SDK v11 / v10 option `sendDefaultPii` is `false` (backend and web use its
v11 replacement, `dataCollection`, set to collect no user info, cookies, headers,
bodies or query parameters).

## Switching it on

Reporting is **off** unless a DSN is configured. The DSN only lets a client send
events; it is still kept out of the repository.

| Project | Setting | Where |
|---|---|---|
| Backend | `SENTRY_DSN` (optional `SENTRY_ENVIRONMENT`, `SENTRY_RELEASE`) | the backend's environment, read in `config/env.js` |
| Website | `NEXT_PUBLIC_SENTRY_DSN` (optional `…_ENVIRONMENT`, `…_RELEASE`) | the website's environment; `NEXT_PUBLIC_` because the browser sends too. Also added to the CSP `connect-src` |
| App | `SENTRY_DSN` | a Dart define, not in the committed `config/*.json`; see `JobTrigger-Frontend/config/README.md` |

The reporting host is the lab's GlitchTip for development; the production
deployment points the same variables at a host the production backend can reach.

## Scrubbing rules

Written once here, implemented three times and tested in each:

| | File |
|---|---|
| Backend | `JobTrigger-Backend/lib/errorReporting/scrub.js`, shapes in `security/credentialShapes.js` (shared with the repository guard `secretMaterialScan.js`) |
| Website | `JobTrigger-Web/src/error-reporting/scrub.ts`, `credential-shapes.ts` |
| App | `JobTrigger-Frontend/lib/core/error_reporting/event_scrubber.dart`, `credential_shapes.dart` |

1. No request or response bodies, no cookies.
2. Headers removed: `Authorization`, `x-auth-token`, `Cookie`, `Set-Cookie`,
   `PRIVATE-TOKEN`, `Proxy-Authorization`, and any header or field whose name contains
   `token`, `secret`, `key`, `password`, `passwd` or `credential`.
3. Query strings, fragments and `user:pass@` are removed from every URL, in fields and in
   message text.
4. Credential shapes are redacted from every string: a Jenkins token (32 hex
   characters, or `11` + 32), a `Basic` or `Bearer` value, a MongoDB URI password, and
   `key=value` / `"key": "value"` pairs with a credential key.
5. No breadcrumbs. `user` is an opaque id at most, never an email or an IP address.
6. After redacting, the event is checked once more against the same shapes. If anything
   is left, or redacting failed, **the event is dropped**. An unscrubbed event is never
   sent or written to disk.

The app additionally reports `AppFailure`s only from the repository layer
(`guardRequest`), and only the unexpected ones (`UnexpectedResponseFailure`,
`UnknownFailure`), by class name and error type — never the error's own text, which can quote
a response body. Expected failures (offline, wrong credentials, a stopped server, a 5xx from
the user's own Jenkins) are not reported.

**Native crashes are off in the app** (`enableNativeCrashHandling: false`, app-hang,
watchdog and ANR tracking too). A native crash report is written by the platform SDK
without passing the Dart scrubber, which would break rule 6. Turn them on only after
adding a native scrubbing hook.

## When the host can't be reached

- **App:** the SDK's own on-disk cache, capped at 30 events (`maxCacheItems`), retried at the next
  launch. Events are scrubbed *before* they are cached.
- **Website browser:** the SDK's offline transport (IndexedDB, at most 30), retried by the SDK.
- **Backend and website server:** `crash-outbox/YYYY-MM-DD.jsonl` (git-ignored, mode 600,
  at most 10 MB and 7 days), one scrubbed event per line, without the DSN. It is retried at
  startup and every 5 minutes; a line is deleted once the host accepts it (or permanently
  rejects it with a 4xx other than 408/429). The backend's normal error log line still goes to
  stdout.

## The app's switch

Profile → Privacy → **Send crash reports**, on by default in every build, stored in
`shared_preferences`. Turning it off stops sending at once and deletes the SDK's offline cache.
Debug and profile builds also show **Send test crash report**, whose message carries made-up
credentials so the dashboard shows they were scrubbed.

## Verifying (iPhone)

1. Mac: GlitchTip running (`make up S="postgres glitchtip"` in the lab), its port reachable on
   the Wi-Fi address (PE-19d).
2. Mac: `SENTRY_DSN_APP=http://<key>@<Mac Wi-Fi address>:3005/<project> scripts/run-on-iphone.sh`.
3. Phone: Profile → Privacy → Send test crash report.
4. Mac: in GlitchTip, the event shows `token=[redacted]` and `https://jenkins.example.com/job/x`,
   with no user, email or query string.
