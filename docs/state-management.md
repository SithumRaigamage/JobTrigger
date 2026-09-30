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

## Feature: history — paging (P11-10)

- `JobHistoryPagesNotifier(jobUrl)` (`AsyncNotifier<HistoryPages>`) loads
  the first page, and `loadMore()` appends the next `historyPageSize`. A
  short page means the end; a failed page keeps what's loaded.
- `JobHistoryFilterNotifier(jobUrl)` (`Notifier<HistoryFilter>`) holds
  the result filter and "started by me". The screen applies the pure
  `filterHistory` to the loaded builds.

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
- `ParameterFilesNotifier` (family by the same form key) holds the files
  chosen for file parameters. `pick()` calls the `parameterFilePicker`
  provider (so it can be faked in tests) and refuses anything over 50 MB.
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
- **Offline (US-JX-20):** a successful `FolderContentsNotifier` listing
  is saved to `JobTreeCache` (platform cache dir, per server and folder).
  On `NetworkFailure` the saved listing is served, and
  `OfflineSnapshotNotifier` (keepAlive, `DateTime?`) holds its save time
  for Home's banner. The cache is cleared on logout and server delete.
- `JobTreeNotifier` (`AsyncNotifier<List<JenkinsJob>>`) is the 6-level
  recursive crawl. It's used only for cross-folder search and the global
  history timeline, and is first fetched when one of those is opened.
- `FolderBreadcrumbNotifier` (`Notifier<List<FolderRef>>`) holds the
  folder **URLs and labels**, never job snapshots, so children always come
  from current data (AUD-10). It watches the active server id, so a server
  switch resets it to the root.
- `JobSearchNotifier` (`Notifier<String>`) holds the search query.
- `PinnedJobsNotifier` (`Notifier<List<PinnedJob>>`, US-JX-11) holds
  URL and label pins per active server id in `shared_preferences`, and
  reloads when the server changes. `pinnedJobStatusProvider(url)` gives a
  pin's live job, or null on 404, meaning a stale pin.
- `branchKindsProvider(projectUrl)` (`FutureProvider`) classifies a
  multibranch project's jobs as branch, PR, or tag, and is watched only
  while Home is inside that project (US-JX-03).
  `MultibranchScanNotifier(projectUrl)` (`Notifier<bool>`, true while
  scanning) POSTs the scan, then polls the indexing log on a timer that's
  cancelled on dispose.
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

## Feature: notifications — build watches (P11-24)

- `BuildWatchNotifier` (`Notifier<List<BuildWatch>>`, keepAlive, US-JX-10)
  holds the builds and jobs the user asked to be notified about, persisted
  by `BuildWatchStore` (`shared_preferences`: job URLs, labels, numbers,
  nothing secret). `watchBuild`/`watchJob` ask `NotificationService` for
  permission first and return a `WatchResult` the bell menu turns into
  copy. While watches exist it checks every 30 s and keeps the background
  task registered through `BackgroundWatchScheduler` (`workmanager`, every
  15 min at the OS's discretion); with none, both stop.
- `runWatchCheck` is the single pass shared by the in-app timer and the
  background isolate: a server whose credentials are gone drops its
  watches, an unreachable one keeps them, and `decideWatch` (pure domain
  logic) says whether to notify and whether to keep each watch.
- `notificationTapsProvider` (`Stream<String>`, keepAlive) emits tapped
  notifications' job URLs; `main.dart` opens job detail for each.

## Feature: app_lock (P11-25)

- `AppLockNotifier` (`Notifier<AppLockState>`, keepAlive, US-JX-21) holds
  the lock settings (`shared_preferences`: on/off, resume timeout, "require
  for actions"; nothing secret) and whether the app is `locked` or
  `obscured`. `AppLockGate`, wrapped around the whole app in
  `MaterialApp.builder`, forwards lifecycle changes to it and covers the
  app while the settings load, while locked, and while it's inactive (the
  app-switcher snapshot). `shouldLockOnResume` (domain) decides the
  timeout; lifecycle changes caused by the OS prompt itself are ignored.
- `confirmSensitive(reason)` is awaited at the top of every sensitive
  action notifier (trigger, which also covers replay; cancel; input
  submit; job enable/disable; node offline toggle; queue cancel). It's a
  no-op unless the user turned on "Require for actions".
- `BiometricService` (`core/platform`) wraps `local_auth` and maps its
  exceptions to `AuthOutcome`, so no plugin types reach the notifier.

## Rules of thumb

- If two screens need the same server-derived state, don't duplicate the
  fetch — lift it to a shared provider and `ref.watch` it from both.
- Polling/timer-owning notifiers are always the plain `Notifier` (not
  `AsyncNotifier`) side-effect kind, separate from the notifier that holds
  the fetched data — keeps "what triggers a refetch" separate from "what the
  data is," which made the original SwiftUI `ViewModel`s hard to test.
