# Migration Strategy

## 1. Approach

**Full rewrite, not incremental port.** The SwiftUI app is not embedded or
run side-by-side with Flutter (no native-module wrapping) — Flutter is a new
client against the *existing* backend, built up feature-by-feature and
validated against the feature matrix in `docs/architecture.md`'s mapping
table. The old iOS app stays live and shippable until the Flutter app
reaches parity and passes QA gates, then it's retired.

## 2. Phases (see `tasks/` for the actionable checklist per phase)

0. **Setup** — repo scaffold, CI, lint config, flavors (dev/staging/prod).
1. **Core infrastructure** — Dio clients, secure storage, config, theme shell.
2. **Auth + tool selection** — login/signup, session persistence, static tool grid.
3. **Credentials management** — server CRUD + switching + connection test.
4. **Jenkins job tree** — recursive fetch, folder nav, search.
5. **Build execution + log streaming + history** — the highest-complexity phase.
6. **Polish + release** — theming parity, accessibility pass, store submission.

Phases are mostly sequential (each depends on the previous), but Phase 6
polish items can start as soon as a feature is functionally complete rather
than waiting for Phase 5 to fully close.

## 3. Feature parity checklist

Use this as the go/no-go list before retiring the SwiftUI app. Each line
should map to a closed task in `tasks/`.

- [x] Signup, login, session persistence across app restarts
- [x] Add/edit/delete Jenkins server, switch active server
- [x] Connection diagnostic (health check) with clear pass/fail states
- [x] Recursive job/folder tree to 6 levels, breadcrumb navigation
- [x] Live job search across the full tree
- [x] Trigger build, with and without parameters (string/choice/boolean)
- [x] Real-time build status polling with progress bar
- [x] Cancel a running build
- [x] Progressive console log streaming, performant at thousands of lines
- [x] Global cross-job history (top 50) + per-job history
- [x] Theme: system/light/dark
- [x] Toast/banner notifications for success/error actions
- [x] App info / version screen

P6-09 regression pass (see `tasks/phase-6-polish-release.md`): every row
above is functionally implemented and covered by passing unit/widget tests
(`flutter analyze` clean, full suite green). This confirms feature
*completeness*, not the dual-platform on-device pass §4/§5 below actually
call for — confirmed concretely rather than assumed: Android has no SDK,
`adb`, or emulator installed in this environment at all (`flutter devices`
finds none, `adb`/emulator tooling isn't installed), and iOS got further
but is still blocked — a real simulator was created and booted, but
Xcode 26.5's build-destination resolution won't target the installed
26.2/26.4 simulator runtimes (needs the matching 26.5 platform, a
multi-GB download requiring interactive setup — see
`tasks/phase-2-auth-tool-selection.md`'s P2-11 for the full diagnostic).
Also still open from §4: all manual
live-Jenkins verification across every phase was against a single local
Jenkins instance (nested folders + flat jobs both exist in its tree, but
it's still one server/one configuration) — the "two differently-configured
servers" QA gate hasn't been exercised. Both are real, named gaps to close
with a device and a second Jenkins instance before store submission, not
silently-passed checkboxes.

## 4. QA gates

Each phase closes only when:
1. `flutter analyze` is clean and unit tests for that phase's repositories
   and notifiers pass.
2. Manual test pass against at least one real Jenkins instance (not just
   mocked responses) — Jenkins' API has enough real-world inconsistency
   (missing fields, polymorphic values) that mocks alone will hide bugs.
3. The relevant row(s) of the parity checklist above are checked off.

Before store submission (end of Phase 6):
- Full regression pass against the parity checklist on both iOS and Android.
- Test against at least two differently-configured Jenkins servers (one
  with folders/nested jobs, one flat) to catch tree-depth and URL-rewriting
  edge cases.
- Cold-start, backgrounding, and token-expiry (401 mid-session) flows
  explicitly tested, not just happy path.

## 5. Rollout

- Internal TestFlight (iOS) + Play internal testing track (Android) at the
  end of Phase 5.
- Dogfood for a fixed window before public release; track crash-free rate
  and any Jenkins-server-shape issues that surface from real usage.
- Keep the SwiftUI app's last build archived and installable (not removed
  from App Store Connect) for a rollback window after Flutter ships, in
  case a parity gap surfaces post-release.

## 6. Risks specific to this migration

| Risk | Mitigation |
|---|---|
| Jenkins' polymorphic JSON (parameter defaults, build `result` vs `building`) breaks codegen'd DTOs on real servers | Test against real Jenkins instances early (Phase 4), not just fixtures written from the docs above |
| URL rewriting logic regresses silently | Dedicated unit tests with fixture JSON containing mismatched internal/external hosts (see `docs/architecture.md §5`) |
| Log streaming performance on Android (historically weaker `ListView` perf under heavy rebuild) | Use `ListView.builder` with a fixed extent or a virtualized text view; test with a multi-thousand-line log fixture before closing Phase 5 |
| Scope creep — adding GitHub Actions/GitLab/CircleCI support "since we're already rewriting" | Explicitly out of scope for this migration; those tool cards stay disabled placeholders unless a separate task authorizes building them |
| Backend auth (JWT) and Jenkins auth (Basic, per-server) getting tangled in a shared Dio/interceptor | Keep them as two entirely separate clients from Phase 1 onward, per `docs/api-reference.md` |
