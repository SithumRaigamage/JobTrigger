# Release checklist (dev-complete; the rest is MANUAL (owner))

Everything development can do for release 1.0 is done. Each line is either
**DONE** (ticked, with its evidence) or **MANUAL (owner)**, with its steps in
`tasks/MANUAL.md`. The submission pack (screenshots, captions, archive and
upload commands) is `docs/store-submission.md`.

- [x] Kill-and-relaunch on the iOS simulator (P2-11), 2026-11-17: signed in,
      process ended, relaunched, landed signed in
      (`integration_test/relaunch.sh`).
- [ ] **MANUAL (owner, M-01):** the same kill-and-relaunch on the physical iPhone.
- [ ] **MANUAL (owner, M-02):** Android on-device build-log jank test (P5-13,
      P11-03). On hold: no Android device. The 50,000-line host test passes.
- [x] App icons and launch screen (Phase 16) and iPhone store screenshots
      (`release/store-screenshots/ios-6.9/`, P6-07, 2026-11-17).
- [ ] **MANUAL (owner, M-05):** Android store screenshots (needs an Android
      emulator, which needs the NDK installed).
- [ ] **MANUAL (owner, M-12):** before the first App Store Connect upload,
      re-check `ios/Runner/PrivacyInfo.xcprivacy` (AUD-56) against the App
      Privacy answers given in App Store Connect, and against any plugin added
      since 2026-10-20 that uses a required-reason API.
- [ ] **MANUAL (owner, M-08, M-09):** internal TestFlight + Play internal
      testing release (P6-11). Prepared: archive and upload commands,
      `flutter build ios --release --no-codesign` verified. Needs the Apple
      Developer and Play Console accounts and signing keys.
- [ ] **MANUAL (owner, M-10):** dogfood window (P6-12). Crash-free rate is
      now readable in GlitchTip.
- [ ] **MANUAL (owner, M-11):** public release, keeping the SwiftUI app
      archived for a rollback window (P6-13).
- [x] Crash reporting host and test crash (P6-08, 2026-11-17): the lab's
      GlitchTip received the app's test crash from the simulator, scrubbed.
- [ ] **MANUAL (owner, M-07):** crash reports from the physical iPhone over the
      Mac's Wi-Fi address (PE-19d), and the three DSNs in the apps' `.env`.
- [ ] **MANUAL (owner, M-12):** the store privacy forms (the tables below are
      ready to copy: App Store → Crash Data, not linked, not tracking; Play →
      Data safety).

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
| Contact Info → Name (student plan only: the full name as on the ID) | Yes, only when a student uploads a document | Yes | No | App Functionality |
| User Content → Other User Content (student plan only: an uploaded student ID or enrolment letter, stored encrypted, deleted 30 days after the decision) | Yes, same | Yes | No | App Functionality |
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

Google Play Data safety: Email address, Name (student plan), User IDs, Purchase history and Other
user content, including the optional student document (collected, linked, app functionality); Crash logs and Diagnostics (collected, optional,
not linked); no data shared with third parties; data encrypted in transit;
account deletion available in the app and on the website.

## Store listing text, per release

The App Store and Google Play text is typed into the stores, so it **cannot
follow `release/tools.json`**. It must describe exactly the tools that
release ships, no more. Each release gets its own version below.

- [ ] **MANUAL (owner, M-12), every release:** rewrite the store text (name/subtitle, short
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

- [ ] **MANUAL (owner, M-12):** create the review account on the production backend (a
      normal account, with no saved servers) and enter its email and
      password in App Store Connect. Needed before store submission.
- [ ] **MANUAL (owner, M-12):** add one line to each store description: "Try the in-app demo
      without an account or a server." (PE-17).
- [x] **On the iPhone** (verified by the owner 2026-11-16): sign-in → **Try the demo** →
      the walkthrough above, then **Exit demo**. See `phase-emergency.md` E2
      "Verify".
