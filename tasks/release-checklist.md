# Release checklist (dev-complete, blocked on external/ops action)

These are **not** scope-cuts — unlike `backlog.md` (deliberately excluded
product surface), everything here is fully specified and, where code is
involved, already implemented. Each item is blocked on something outside
what development in this environment can resolve: a real device, real
artwork, store accounts, real users, or a real production action. Phase 2
and Phase 6 are marked `done` in `tasks/README.md` despite these being open,
because "done" there means dev-complete, not "in production." Full
investigation detail for each item lives at its source task id — this file
only tracks what's left and why.

- [ ] Real device kill-and-relaunch verification (source: `phase-2-auth-tool-selection.md`
      P2-11). Widget-test substitute exists and passes; no working iOS
      simulator destination or connected physical device was available in
      this environment to run the real manual test. Needs someone with a
      working local iOS toolchain (or the iOS 26.5 simulator platform
      installed via Xcode) to confirm.
- [ ] Android on-device build-log jank/performance test (source:
      `phase-5-build-execution-logs-history.md` P5-13). A 5,000-line log
      fixture confirms `ListView.builder` actually virtualizes (well under
      200 live widgets, not 5,000) and doesn't throw/hang — evidence the
      mechanism is sound, not a substitute for real on-device scroll
      measurement. Update 2026-11-08: an emulator (Medium_Phone_API_37.0)
      and the fixture Jenkins `big-log` job (50,000 lines) are now ready, and
      a 50,000-line host test passes. Remaining: build the profile APK on a
      fast connection, scroll the `big-log` build, record frame times.
- [ ] App icons, splash screens, store screenshots for both platforms
      (source: `phase-6-polish-release.md` P6-07). The original SwiftUI app
      never shipped real artwork to port from. Needs real source artwork
      supplied by the team — not agent-generated — before store submission
      can proceed.
- [ ] Before the first App Store Connect upload: re-check
      `ios/Runner/PrivacyInfo.xcprivacy` (AUD-56) against the App Privacy
      answers given in App Store Connect, and against any plugin added
      since 2026-10-20 that uses a required-reason API.
- [ ] Internal TestFlight + Play internal testing track release (source:
      `phase-6-polish-release.md` P6-11). Needs an Apple Developer account
      + App Store Connect access + code-signing certificates, and a Google
      Play Console account + signing key. The Android upload-key setup is
      in `docs/deployment.md`, "Android release signing" (P12-10); the
      build side is ready, and only the key itself is missing. Also blocked on the icon/splash
      item above, and on revisiting the crash-reporting decision
      (`backlog.md`) before real users are involved.
- [ ] Dogfood window — track crash-free rate and Jenkins-server edge cases
      from real usage (source: `phase-6-polish-release.md` P6-12). Needs
      real users on real devices over a real time window; currently no
      crash-free-rate signal exists since crash reporting was deliberately
      skipped (see `backlog.md`) — worth revisiting before this starts.
- [ ] Public release; keep the SwiftUI app archived (not delisted) for a
      rollback window per `docs/migration-strategy.md §5` (source:
      `phase-6-polish-release.md` P6-13). App Store / Play Store
      submission — a real-world, hard-to-reverse action on a shared/public
      system. Requires your explicit action and store-account access.
      Blocked on the items above.
- [ ] Crash reporting on a real device and host (source: `phase-emergency.md`
      E3, PE-19c/d, PE-24..27). Unit and widget tests pass; delivery to GlitchTip, the
      offline cache, `pod install` with the Sentry SDK, the Sentry SDK's own privacy manifest
      and the "Send crash reports" switch clearing the cache have not been run on a phone.
      Also owed: the App Store privacy answers (Data Types: Diagnostics → Crash Data,
      not linked, not tracking) and Google Play's Data safety form (crash logs, optional).

## App Store privacy answers (PE-06 / PE-27, checked 2026-11-16)

Checked against `ios/Runner/PrivacyInfo.xcprivacy`, the merged privacy
manifests of every pod in the profile build, and `/privacy`. Enter these in
App Store Connect → App Privacy. Tracking: **No** (no ad identifier, no
tracking domains).

| Data type (Apple's name) | Collected | Linked to user | Tracking | Purpose |
|---|---|---|---|---|
| Contact Info → Email Address | Yes | Yes | No | App Functionality |
| User Content → Other User Content (saved server names, URLs, usernames, encrypted tokens) | Yes | Yes | No | App Functionality |
| Diagnostics → Crash Data | Yes (opt-out in Profile) | No | No | App Functionality |
| Diagnostics → Other Diagnostic Data (device model and OS version sent with a report) | Yes (same switch) | No | No | App Functionality |
| Purchases → Purchase History (JobTrigger Pro subscription, via RevenueCat) | Yes, only in builds with billing keys | Yes | No | App Functionality |
| Identifiers → User ID (the JobTrigger account id RevenueCat is logged in with) | Yes, same | Yes | No | App Functionality |
| Diagnostics → Performance Data | No (tracing is off) | n/a | n/a | n/a |

Decided 2026-11-16: the app manifest declares Crash Data and Other
Diagnostic Data (not linked, app functionality), matching this table and
`/privacy`. Performance Data is not collected (`tracesSampleRate = 0`).
Phase 20 (PE-06 follow-up, 2026-11-16): the manifest and the two
Purchases / Identifiers rows above now cover RevenueCat. `/privacy` still
needs a RevenueCat paragraph (P20-34, website PR).

Required-reason APIs: the app declares UserDefaults CA92.1 + 1C8F.1
(`home_widget` shares data through the App Group and ships no manifest),
FileTimestamp C617.1 and SystemBootTime 35F9.1. Sentry, Flutter,
`shared_preferences`, `flutter_local_notifications`, `workmanager` and the
widget extension ship manifests with reasons the app already covers. Re-run
this check whenever a plugin is added.

Google Play Data safety: Email address, User IDs, Purchase history and Other
user content (collected, linked, app functionality); Crash logs and Diagnostics (collected, optional,
not linked); no data shared with third parties; data encrypted in transit;
account deletion available in the app and on the website.

## Store listing text, per release

The App Store and Google Play text is typed into the stores, so it **cannot
follow `release/tools.json`**. It must describe exactly the tools that
release ships, no more. Each release gets its own version below.

- [ ] **Owner, every release:** rewrite the store text (name/subtitle, short
      and full description, screenshots' captions, review notes) for that
      release's tools, from `release/tools.json`, before submitting. Check
      the website's home, integrations and pricing pages say the same.

### Release 1.0 (Jenkins only)

> **Subtitle / short description (Play, 80 characters):**
> Trigger and watch your Jenkins builds from your phone.
>
> **Full description:**
> JobTrigger puts your Jenkins in your pocket. Browse jobs and folders,
> trigger a build with any parameter, watch the console stream live, see
> which stage or test failed, and get a notification when a build finishes.
> Pin the jobs you watch, put them on your home screen, and lock the app
> with Face ID or your fingerprint.
>
> Set up your servers on your laptop at the JobTrigger website, or in the
> app: your phone talks to your Jenkins directly, and your tokens are stored
> encrypted. Free for one server; JobTrigger Pro adds more servers and the
> extras.
>
> Try the in-app demo without an account or a server.
>
> JobTrigger is an independent app and is not affiliated with the Jenkins
> project.

Do **not** mention GitHub Actions, SonarQube, GitLab or CircleCI in the 1.0
listing, screenshots or keywords. They arrive in 1.1 (SonarQube), 1.2 (GitHub
Actions) and later; each of those releases gets its own text here.

**App Review notes for 1.0:** use the notes below, but replace the bullet
"GitHub Actions and SonarQube: choose them under Profile → CI tool" with:
"This release works with Jenkins only." Nothing else changes: the demo's
GitHub and SonarQube samples are not reachable in 1.0, because tool selection
offers only released tools.

## App Review notes: how to open the demo (PE-18)

Paste this into App Store Connect → App Review Information → Notes (and the
Play Console equivalent). The review account's password goes only into the
store's own fields, never into this repository.

> JobTrigger controls the reviewer's own CI servers, so a reviewer without
> one would see an empty app. To see everything without an account or a
> server: on the sign-in screen tap **Try the demo**. The app then runs on
> sample data built into it and sends no network requests.
>
> - Jenkins: browse the folders, open `demo-app` → `main`, and tap **Trigger
>   build**, then **Trigger**. The run goes through its stages and the log streams to SUCCESS in
>   about 20 seconds. Open `demo-app` → `feature-login` for a failed build
>   with its log and test report.
> - GitHub Actions and SonarQube: choose them under **Profile → CI tool**.
>   SonarQube has a project that fails its quality gate.
> - Other actions (cancel, replay, edit credentials, account changes) show
>   "Not available in demo".
> - **Exit demo** in the banner at the top returns to sign-in.
>
> To check the real sign-in flow, use the review account below.
> Email: `<review account email>`; password: in the Password field of this
> form.

- [ ] **Owner:** create the review account on the production backend (a
      normal account, with no saved servers) and enter its email and
      password in App Store Connect. Needed before store submission.
- [ ] **Owner:** add one line to each store description: "Try the in-app demo
      without an account or a server." (PE-17).
- [x] **On the iPhone** (verified by the owner 2026-11-16): sign-in → **Try the demo** →
      the walkthrough above, then **Exit demo**. See `phase-emergency.md` E2
      "Verify".
