# Integration Testing (End-to-End)

Real end-to-end tests that drive the actual app on a connected
simulator/device — real navigation, real taps, real network calls against a
running backend. Complements (doesn't replace) the unit/widget suite in
`JobTrigger-Frontend/test/` (`flutter_test`, `mocktail`, `riverpod_test`).

Uses Flutter's own `integration_test` package — not Playwright/a browser
tool. Playwright automates web browsers and has no way to drive a native
iOS/Android app; `integration_test` is the Flutter-native equivalent and
runs on the exact same simulator you test on manually.

## Prerequisites

1. Backend running with the dev account seeded:
   ```bash
   ./setup-dev.sh
   ```
   (or `USE_DOCKER=true ./setup-dev.sh` for local MongoDB — see
   [Dev Setup](./dev-setup.md))
2. A connected simulator/device (`flutter devices` to check)

## Running

```bash
cd JobTrigger-Frontend
flutter test integration_test/app_test.dart --dart-define-from-file=config/dev.json -d "iPhone Air"
```

Takes ~50s — it's a real app build + real network round-trips, not mocked.

## What's covered today (`integration_test/app_test.dart`)

| Scenario | Asserts |
|---|---|
| Login screen renders pre-selection | `primary` color is `AppColors.brandSeed` (blue), not a tool accent |
| Full flow: login → tool selection → select Jenkins → Home | Login succeeds against the real backend; ToolSelectionScreen still shows blue; tapping Jenkins navigates to Home ("Jobs" AppBar) with `primary` now `AppColors.ciToolJenkins` (red) |

This set exists specifically as regression coverage for the per-tool-theming
feature (see `main.dart`, `ActiveToolNotifier`, `AppTheme`) — it was written
right after a real bug where the theme stayed tool-tinted across app
restarts due to stale persisted state.

## Test-only widget keys

A few widgets carry stable `Key`s purely so integration tests can find them
without brittle text/type finders:

- `login_email_field`, `login_password_field`, `login_submit_button` — `LoginScreen`
- `tool_card_<CiTool.name>` (e.g. `tool_card_jenkins`) — `ToolSelectionScreen`

Add a `Key` the same way for any new screen a future scenario needs to
target.

## Adding more scenarios

Add new `testWidgets(...)` blocks to `integration_test/app_test.dart` (or a
new file in `integration_test/` for a distinct flow — e.g.
`job_trigger_test.dart` for trigger-a-build once that becomes a priority).
Each `testWidgets` calls `app.main()` itself; they run sequentially against
the same live backend, so use data that's safe to create repeatedly (or
clean up in the test) rather than assuming a pristine database per test.

## Known limitations

- **Not run in CI** — these need a live backend + a booted simulator,
  neither of which `.github/workflows/flutter-ci.yml` currently provisions.
  Today this is a local, manual regression check; wiring it into CI (e.g.
  spinning up MongoDB + backend + an iOS simulator runner) is future work,
  not done as part of this initial setup.
- **Shared app state across `testWidgets` in one file** — since `app.main()`
  doesn't reset previous tests' provider state, keep scenarios in one file
  roughly sequential/dependent (as the two here are) rather than assuming
  full isolation.

## Fixture Jenkins (real-server verification)

`NFR-TEST-02` requires Jenkins-facing behaviour to be verified against a
real Jenkins, not only against mocked HTTP. `tools/jenkins-fixture/` is a
disposable, fully scripted Jenkins for that (task P11-01).

```bash
tools/jenkins-fixture/fixture.sh up      # build + start on http://localhost:8090, seed builds
tools/jenkins-fixture/fixture.sh test    # run the `fixture`-tagged Flutter tests against it
tools/jenkins-fixture/fixture.sh creds   # print the URL and API tokens (e.g. to add it as a server in the app)
tools/jenkins-fixture/fixture.sh down    # stop, keeping data
tools/jenkins-fixture/fixture.sh reset   # stop and delete all data and generated credentials
```

- **Needs:** Docker running. The first build takes a few minutes while
  plugins download.
- **Pinned:** Jenkins `2.568.3-lts-jdk21`. Plugins are listed in
  `plugins.txt`. Everything is configured by `casc.yaml` (Configuration as
  Code plus Job DSL). There is no setup wizard or manual step.
- **Credentials:** `fixture.sh up` generates random passwords and one API
  token per user into `tools/jenkins-fixture/.fixture-credentials`, which is
  git-ignored and `chmod 600`. Nothing secret is committed. The only
  committed "credential" is the obviously fake `deploy-creds`, used by the
  credentials-parameter fixture.
- **Users:** `admin` has full access. `viewer` is read-only, so the
  permission (403) paths are testable.
- **Deliberate traps:**
  - Jenkins' configured root URL is `http://jenkins.internal:8080/`, which
    doesn't match `localhost:8090`. That forces the app's URL rewriting
    (`docs/architecture.md` §5) to work for real.
  - CSRF protection is on.
  - `agent-1` is a permanent agent that never connects, so there's always
    one offline node.
- **Bound to `127.0.0.1` only:** never expose this server on a network.

| Seeded job | Scenario (story) |
|---|---|
| `nested/level-2/…/level-7/deep-job` | 7-level folder tree (US-TREE-*, AUD-19) |
| `freestyle-simple` | Parameterless trigger, cancel (US-JOB-02/05) |
| `params-all` | One parameter of every core type, including password, file, run, and credentials (US-JX-01/02) |
| `pipeline-stages` | Sequential and parallel stages with a failing branch (US-PIPE-04, US-JX-04) |
| `pipeline-input-simple` · `pipeline-input-params` | Paused input steps, without and with parameters (US-PIPE-05) |
| `big-log` | 50,000-line ANSI-colored, timestamped log with an `ERROR` marker (US-JX-07, P5-13) |
| `junit-report` | Pass, fail with a stack trace, and skip; build goes UNSTABLE (US-PIPE-06, US-JX-08) |
| `artifacts` | 25 small artifacts, a path containing a space, and a 60 MB artifact (US-PIPE-07, AUD-21) |
| `slow-build` | 90 s build without concurrent builds, for polling, cancel, and queue tests (US-JOB-04/05, US-JX-09) |
| `upstream-freestyle` → `downstream-freestyle`, `upstream-pipeline` | Upstream and downstream links (US-PIPE-09) |
| `disabled-job` | Disabled job (US-JX-13) |
| `sample-multibranch` | Branches `main` and `feature/login` (seen as `feature%2Flogin`), tag `v1.0.0`, and views `default`/`tags` (US-JX-03) |

**Writing a fixture test:** put it under `JobTrigger-Frontend/test/fixture/`
with `@Tags(['fixture'])`. Get the server lazily
(`late final jenkins = FixtureJenkins.fromEnvironment();`) and use the
helpers in `fixture_support.dart`: `triggerAndAwaitStart`,
`awaitCompletion`, `pollUntil`, and `expectOk`. Tests go through the
production `buildJenkinsDio` and `JenkinsRepositoryImpl`. `dart_test.yaml`
skips the tag in normal runs and in CI.
