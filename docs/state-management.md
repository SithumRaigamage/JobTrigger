# State Management — Provider Map

All providers are code-generated with `@riverpod` (`riverpod_generator`).
Global/singleton-ish providers below; per-screen notifiers live next to
their screen under `presentation/features/<feature>/`.

## Global providers (`core/` or `presentation/navigation/`)

| Provider | Type | Purpose |
|---|---|---|
| `dioBackendProvider` | `Provider<Dio>` | Configured Dio for backend API, JWT interceptor attached |
| `secureStorageProvider` | `Provider<SecureStorageService>` | Wraps `flutter_secure_storage` |
| `authRepositoryProvider` | `Provider<AuthRepository>` | |
| `authNotifierProvider` | `AsyncNotifier<AuthState>` | Holds current `User?`/logged-in state; root nav (`go_router` redirect) watches this |
| `credentialsRepositoryProvider` | `Provider<CredentialsRepository>` | |
| `credentialsNotifierProvider` | `AsyncNotifier<List<Credential>>` | List of saved Jenkins servers |
| `activeServerNotifierProvider` | `Notifier<Credential?>` | Currently active server; persisted id in `shared_preferences`, rehydrated on app start |
| `jenkinsClientProvider` | `Provider<Dio>` | Rebuilt (via `ref.watch(activeServerNotifierProvider)`) whenever the active server changes |
| `jenkinsRepositoryProvider` | `Provider<JenkinsRepository>` | Depends on `jenkinsClientProvider` |
| `themeNotifierProvider` | `Notifier<ThemeMode>` | System/Light/Dark, persisted in `shared_preferences` |
| `toastControllerProvider` | `Provider<ToastController>` | Thin wrapper to show global success/error banners from anywhere |

## Feature: auth

- `LoginNotifier` / `SignupNotifier` (`AsyncNotifier<void>`) — hold
  form-submit state (`loading`/`error`); on success call
  `authNotifierProvider.notifier.setSession(user)`. `LoginNotifier.login`
  also takes `rememberMe` and, only after a successful login, calls
  `rememberedEmailNotifierProvider.notifier.remember(email)` or `forget()`.
- `RememberedEmailNotifier` (`AsyncNotifier<String?>`) — the "Remember me"
  email, in `shared_preferences`. **Email only, never the password**
  (AUD-01). Its `build()` also deletes the legacy `login_saved_password`
  key that builds before AUD-01 wrote.

## Feature: job_detail — parameters (P11-04)

- `ParameterEditsNotifier` (`Notifier<Map<String, String>>`, family by a
  form key) holds **only the user's edits**. The key is the job URL for
  the trigger form, `replay:<buildUrl>` for replay, and
  `input:<buildUrl>#<inputId>` for an input step. What a form shows is
  `effectiveParameterValues(definitions, edits)`, a pure function in
  `domain/jenkins/parameter_values.dart`. So a 5s poll re-fetching the job
  never resets typed values, and a field rebuilt after scrolling keeps
  them (AUD-18). Screens read the edits **at tap time** when confirming,
  not from a closure captured at build.
- `TriggerBuildNotifier.trigger` sends
  `triggerParameters(definitions, values)`. That omits blank password
  parameters so Jenkins applies its stored default (US-JX-01), and every
  trigger path (job detail, replay) gets the rule.

## Feature: tool_selection

- No notifier needed initially (static grid); if GitHub Actions/GitLab/etc.
  become real (not just placeholder cards), add a `CiToolAvailabilityProvider`.

## Feature: settings / server management

- `credentialsNotifierProvider` (list, above)
- `ServerFormNotifier` — add/edit form state + "test connection" action,
  calls `jenkinsRepositoryProvider.testConnection(draftCredential)` against
  a throwaway Dio instance (not the active one) so testing a new server
  doesn't disturb the active session.

## Feature: home (job tree)

- `FolderContentsNotifier` (`AsyncNotifier<List<JenkinsJob>>`, family by
  folder URL, with `''` for the root; P11-05) fetches **one level** via
  `fetchFolder`. Home browses with this, so there's no depth limit and no
  whole-tree download on load (AUD-19/20).
- `JobTreeNotifier` (`AsyncNotifier<List<JenkinsJob>>`) is the 6-level
  recursive crawl. It's used only for cross-folder search and the global
  history timeline, and is first fetched when one of those is opened.
- `FolderBreadcrumbNotifier` (`Notifier<List<FolderRef>>`) holds the
  folder **URLs and labels**, never job snapshots, so children always come
  from current data (AUD-10). It watches the active server id, so a server
  switch resets it to the root.
- `JobSearchNotifier` (`Notifier<String>`) holds the search query.
- `visibleJobsProvider` (`Provider<AsyncValue<List<JenkinsJob>>>`) is what
  Home renders. With no query, it's the current folder's contents. It also
  watches the root and every breadcrumb ancestor, so "Back" is instant and
  nothing is cached once Home is left, with no timers involved. With a
  query, it's the crawl flattened and filtered by `label` or `name`.
  `refreshVisibleJobs(ref)` re-fetches whichever source is showing.

## Feature: job_detail

- `JobDetailNotifier` (`AsyncNotifier<JenkinsJob>`) — fetches job detail tree.
- `BuildStatusPollingNotifier` (`Notifier<void>`, side-effect only) —
  starts a `Timer.periodic(5s)` that calls `ref.invalidate(jobDetailNotifierProvider)`
  while `lastBuild.building == true`; cancels in `ref.onDispose`.
- `TriggerBuildNotifier` (`AsyncNotifier<void>`) — builds the parameter form
  payload and POSTs; on success, triggers a `JobDetailNotifier` refresh.
- `CancelBuildNotifier` (`AsyncNotifier<void>`) — POST stop + optimistic
  local status flip.

## Feature: build_log

- `BuildLogNotifier` (`AsyncNotifier<String>`, accumulating) — owns the
  `start` offset, appends new text on each poll, stops when
  `X-More-Data` is false; cancels its internal timer in `ref.onDispose`.

## Feature: history

- `GlobalHistoryNotifier` (`AsyncNotifier<List<HistoryEntry>>`) — traverses
  the already-fetched job tree (reuses `JobTreeNotifier`'s data where
  possible instead of re-fetching) to build the cross-job top-50 timeline.
- `JobHistoryNotifier` — same shape, scoped to one job's `builds[]`.

## Feature: profile / app_info

- `ProfileNotifier` — thin read of `authNotifierProvider`'s user, no own
  network calls beyond what auth already fetched.
- `AppInfoNotifier` (`AsyncNotifier<AppInfo>`) — GET `/api/appinfo`, cached.

## Rules of thumb

- If two screens need the same server-derived state, don't duplicate the
  fetch — lift it to a shared provider and `ref.watch` it from both.
- Polling/timer-owning notifiers are always the plain `Notifier` (not
  `AsyncNotifier`) side-effect kind, separate from the notifier that holds
  the fetched data — keeps "what triggers a refetch" separate from "what the
  data is," which made the original SwiftUI `ViewModel`s hard to test.
