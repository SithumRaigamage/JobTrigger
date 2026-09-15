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
  `authNotifierProvider.notifier.setSession(user)`.

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

- `JobTreeNotifier` (`AsyncNotifier<List<JenkinsJob>>`) — fetches full tree
  from `jenkinsRepositoryProvider`; `refresh()` invalidates self.
- `JobSearchNotifier` (`Notifier<String>`) — search query; a derived
  `filteredJobsProvider` (plain `Provider`, computed) flattens the tree and
  filters by name, watched by `JobTreeNotifier`'s output.
- `FolderBreadcrumbNotifier` (`Notifier<List<JenkinsJob>>`) — navigation
  stack for folder drill-down; pure local UI state, no repository calls.

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
