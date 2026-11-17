# MANUAL (owner) tasks — the single list

Every unticked item in `tasks/*.md` and `tasks/release-checklist.md` is either
**DONE** (ticked, with evidence in the task file) or appears here as a
**MANUAL (owner)** task with an `M-XX` id. This file is the one place to look
for what still needs you, what to do, and why nobody else can do it. When you
finish one, tell me which `M-XX` it was and what you saw; I'll tick the source
task(s) and update the trackers.

Nothing here can be closed by an agent: each needs a physical device you own,
an account only you hold, a credential that must never enter this repository,
a real-world/public action, or a business decision. The code and the prepared
commands are already done.

**Your iPhone is the test device (CLAUDE.md §10):** install with
`scripts/run-on-iphone.sh`, and anything the phone reaches runs on the Mac's
Wi-Fi address, currently **`192.168.1.53`** (re-check with
`ipconfig getifaddr en0` — it changes with the network). Use the Mac's local
hostname `Sithums-MacBook-Pro.local` if the IP changes; `IPHONE.md` covers both.

| Id | Task | Source | On hold? |
|---|---|---|---|
| [M-01](#m-01--kill-and-relaunch-on-the-physical-iphone) | Kill-and-relaunch on the physical iPhone | P2-11 | no |
| [M-02](#m-02--android-on-device-log-jank-test) | Android on-device log jank test | P5-13, P11-03 | **yes — no Android device** |
| [M-03](#m-03--sonarqube-iphone-auth-isolation-and-real-server-pass) | SonarQube iPhone auth + real-server pass | P10-14, P10-15, P20-07 | no |
| [M-04](#m-04--sonarcloud-account-and-organization) | SonarCloud account and organization | P10-15 | no |
| M-05 — Android store screenshots | DONE 2026-11-17 (P6-07) | P6-07 | — |
| [M-06](#m-06--github-fine-grained-token-and-iphone-checks) | GitHub fine-grained token + iPhone checks | P8-26, P8-27, PE-41, PE-42 | no |
| [M-07](#m-07--crash-reporting-dsns-and-iphone-test-crash) | Crash-reporting DSNs + iPhone test crash | P6-08, PE-19d/e | no |
| [M-08](#m-08--app-store-connect--testflight) | App Store Connect / TestFlight | P6-11 | no |
| [M-09](#m-09--play-console-internal-testing) | Play Console internal testing | P6-11 | no |
| [M-10](#m-10--dogfood-window) | Dogfood window | P6-12 | after M-08/M-09 |
| [M-11](#m-11--public-release) | Public release | P6-13 | after M-10 |
| [M-12](#m-12--store-submission-content) | Store text, privacy answers, review notes | release-checklist.md | before M-08/M-09 |
| [M-13](#m-13--website-go-live) | Website go-live | P15-22, P15-24, PE-03 | after M-08/M-09 |
| [M-14](#m-14--production-backend-deploy-and-keys) | Production backend deploy + keys | P20-05, PE-30, PE-31 | no |
| [M-15](#m-15--billing--subscriptions-launch) | Billing / subscriptions launch | Phase 20 (list below) | no |
| [M-16](#m-16--firebase-server-push) | Firebase server push | NR-06b | approval needed |
| [M-17](#m-17--github-fallback-decision) | GitHub fallback decision | PE-43 | only if M-06 finds a blocker |

---

## M-01 — Kill-and-relaunch on the physical iPhone

**Source:** P2-11 (`tasks/phase-2-auth-tool-selection.md`).
**Done already:** the same check on the iOS simulator (2026-11-17,
`integration_test/relaunch.sh`): signed in, process ended, relaunched, landed
on the signed-in tool-selection screen, never login.
**Why only you:** the gate is a real iPhone — your device, on your Wi-Fi,
signed in to your account. The agent's environment only had simulators, and
CLAUDE.md §10 names you as the iPhone tester.

1. Mac: start the backend (`./setup-dev.sh`) and install the app with
   `scripts/run-on-iphone.sh` (a profile build; `IPHONE.md`).
2. Phone: sign in with **Remember my email** ticked — that switch is what keeps
   the session (P19-01).
3. Phone: force-quit the app (swipe it away in the app switcher), wait ~2 s,
   then reopen it from the Home screen.
4. Phone: confirm you land on the tool-selection screen or Home, **not** the
   login screen, and take a screenshot.

**Evidence to bring back:** that screenshot + "landed signed in".

## M-02 — Android on-device log jank test

**Source:** P5-13 (`tasks/phase-5-build-execution-logs-history.md`), P11-03
(`tasks/phase-11-jenkins-extended.md`). Also covers the Android half of P20-52.
**On hold — you have no Android device.**
**Done already:** a 50,000-line host test (`console_log_viewer_50k_test.dart`)
decodes in under 5 s, keeps under 200 live `RichText` widgets after 20 flings,
and `jumpToLine` reaches the error marker; the fixture Jenkins `big-log` job is
ready. That proves the virtualization mechanism, not real device frame times.
**Why only you:** the task explicitly asks for a mid-range Android device, and
there is none here — this Mac's Android NDK install is broken, so even an
emulator profile build can't be produced.

1. Mac: fix the Android NDK / use the prepared `Medium_Phone_API_37.0`
   emulator and build the profile APK over a fast connection.
2. Mac: start the fixture Jenkins `big-log` job (50,000 lines).
3. Android device: add the Jenkins server using the Mac's Wi-Fi address, not
   `localhost`; open the failing build's console log and fling-scroll it.
4. With Developer Options → GPU/frame-time profiling on, record frame times
   and confirm no sustained dropped frames over the 50k-line log.
5. For P20-52, also do the Android Play license-tester sandbox pass (M-15).

**Evidence:** the frame-time recording / note, and the sandbox result.

## M-03 — SonarQube iPhone auth isolation and real-server pass

**Source:** P10-14, P10-15 (`tasks/phase-10-sonarqube.md`), P20-07, PE-41/42's
SonarQube half.
**Done already:** automated isolation tests plus the live HTTP check against
the lab server (a bad token and no token both get 401 from
`api/components/search_projects`). The lab SonarQube 26.1.0 is up at
`192.168.1.53:9000`, bound on the network.
**Why only you:** the remaining checks need your SonarQube token (never
committed; agents don't read `.env`, CLAUDE.md §8) and your physical iPhone.

1. Phone: install with `scripts/run-on-iphone.sh`; add the SonarQube server at
   `http://192.168.1.53:9000` with your token.
2. Phone: make SonarQube return a 401 (bad token), then confirm the app keeps
   the backend session and the Jenkins/GitHub clients — no global logout. In
   the other direction, sign out of the backend and confirm the SonarQube
   client keeps working with its own credentials.
3. Phone: walk the SQ-CRED/PROJ/QUALITY screens (projects, measures, issues,
   gate, file source) against the lab server. `api/measures/search`,
   `api/sources/show` and `api/rules/show` response shapes are only
   documented, not verified — this pass is the check.

**Evidence:** note + screenshots of the auth-isolation behaviour.

## M-04 — SonarCloud account and organization

**Source:** P10-15 (`tasks/phase-10-sonarqube.md`).
**Why only you:** the epic covers **both** flavors — self-hosted SonarQube
(M-03) and SonarCloud. Only you can create/sign in to a SonarCloud account,
create an organization and generate a token; those credentials never enter the
repository.

1. Sign in to SonarCloud with your GitHub account, create an organization and
   a project, and generate a token.
2. Phone: add it as a SonarQube server in the app and repeat the screen walk
   from M-03 against the cloud flavor.
3. Confirm both flavors are covered, so P10-15 can close.

**Evidence:** note that both flavors were verified.

## M-05 — Android store screenshots (DONE 2026-11-17)

**Source:** P6-07 (`tasks/phase-6-polish-release.md`). No longer an owner task:
captured directly this session; record kept here for the release trail.
**What was done:** installed the missing Android NDK (r28c, SHA-1 verified),
booted the `Medium_Phone_API_37.0` emulator at 1080×2160, and captured five
matching Jenkins shots in demo mode with
`integration_test/store_screenshots_test.dart`. The capture test was made
cross-platform (one surface conversion at the start on Android, a no-op on
iOS). Output is five JPEGs without alpha in
`release/store-screenshots/android-2by1/`, each exactly 1080×2160 (Google
Play's 2:1 limit); the taller iPhone 6.9" shots can't be reused. Captions and
the retake command are in `docs/store-submission.md`.
**Evidence:**
`release/store-screenshots/android-2by1/{01-jobs,02-folder,03-job,04-failing-job,05-build-log}.jpg`.
No owner action remains for this item.

## M-06 — GitHub fine-grained token and iPhone checks

**Source:** P8-26, P8-27 (`tasks/phase-8-github-actions.md`), PE-41, PE-42.
**Done already (2026-11-17):** the live API half through the app's own client
against the real throwaway repo `SithumRaigamage/jobtrigger-actions-test`
(three workflows: with inputs, no inputs, disabled) — repos and workflows
listed, dispatch with inputs queued, runs/jobs/steps/logs/history read; an
invalid token is an `AuthFailure` kept apart from permission failures.
**Why only you:** a fine-grained personal access token cannot be created
through the API — only you can create it in GitHub's settings — and the final
walk-through is on your iPhone.

1. Mac: GitHub → Settings → Developer settings → Personal access tokens →
   Fine-grained tokens → create one with read + Actions write, scoped to
   `SithumRaigamage/jobtrigger-actions-test`.
2. Phone: install with `scripts/run-on-iphone.sh`, add the GitHub credential
   with that token, and confirm a GitHub 401 keeps the backend session and the
   Jenkins/SonarQube clients alive.
3. Phone: walk all three workflows in the app — list them, dispatch the one
   with inputs, open a run, its jobs and steps and logs, then run history.
4. When you're done with the token check, tell me so I can delete the
   throwaway repo (see "Held for your signal" at the bottom).

**Evidence:** note + screenshots of the 401 isolation and the run walk-through.

## M-07 — Crash-reporting DSNs and iPhone test crash

**Source:** P6-08 (`tasks/phase-6-polish-release.md`), PE-19d, PE-19e
(`tasks/phase-emergency.md`); rules in `docs/error-reporting.md`.
**Done already (2026-11-17):** the lab GlitchTip received the app's own test
crash from the simulator, scrubbed (`token=[redacted]`,
`url=https://jenkins.example.com/job/x`); the three GlitchTip projects exist
and sign-up is off; a scrubber bug that dropped every event was found and
fixed.
**Why only you:** the DSNs go into the apps' `.env` files, which agents never
read or write (CLAUDE.md §8), and the last hop is from your iPhone over the
Mac's Wi-Fi.

1. Mac: GlitchTip is running (`make up S="postgres mailpit glitchtip"` in the
   lab, port 3005). Copy the three projects' DSNs into the three apps' `.env`
   files (`jobtrigger-app`, `jobtrigger-web`, `jobtrigger-backend`). Never
   commit them.
2. Mac: bind port 3005 on the LAN for development, the same rule `IPHONE.md`
   uses for the backend.
3. Mac: `SENTRY_DSN_APP=http://<key>@192.168.1.53:3005/<project> scripts/run-on-iphone.sh`.
4. Phone: Profile → Privacy → **Send test crash report**.
5. Mac: in GlitchTip, confirm the event shows `token=[redacted]` and
   `https://jenkins.example.com/job/x`, with no user, email or query string.

**Evidence:** screenshot of the GlitchTip event.

## M-08 — App Store Connect / TestFlight

**Source:** P6-11 (`tasks/phase-6-polish-release.md`).
**Done already:** `flutter build ios --release --no-codesign --dart-define-from-file=config/prod.json`
builds; the signed archive/upload commands are written in
`docs/store-submission.md`.
**Why only you:** an Apple Developer account, distribution certificate,
profiles and App Store Connect access cannot be created or used on your behalf.

1. Mac: `flutter build ipa --release --dart-define-from-file=config/prod.json`
   (needs your Apple Distribution certificate and profiles).
2. Mac: upload with the `xcrun altool` command in `docs/store-submission.md`,
   or drag the `.ipa` into Transporter.
3. App Store Connect: select the build under TestFlight (internal group).

**Evidence:** the build shows as processed in TestFlight.

## M-09 — Play Console internal testing

**Source:** P6-11. **Why only you:** a Play Console account and the Android
upload signing key are yours alone (`docs/deployment.md`, "Android release
signing", P12-10).

1. Mac: `flutter build appbundle --release --dart-define-from-file=config/prod.json`
   (signed via `android/key.properties`).
2. Upload the `.aab` to Play Console → Testing → Internal testing; complete
   the Data safety form from the table in `tasks/release-checklist.md`.

**Evidence:** the release is available to internal testers.

## M-10 — Dogfood window

**Source:** P6-12. **Why only you:** it needs real users on real devices over
a real time period — not reproducible in this environment. Crash reporting now
exists, so there is a signal to watch.

1. Enrol internal testers via TestFlight (M-08) and Play internal (M-09).
2. Run for the agreed window; watch the crash-free rate in GlitchTip and
   collect Jenkins-server edge cases from real usage.

**Evidence:** notes on crash-free rate and any edge cases found.

## M-11 — Public release

**Source:** P6-13. **Why only you:** a store submission is a hard-to-reverse
public action on shared systems, and it needs your explicit action and store
accounts. Do this only after M-08, M-09 and M-10.

1. Promote the tested internal builds to production in both stores.
2. Keep the SwiftUI app **archived (not delisted)** for a rollback window, per
   `docs/migration-strategy.md §5`.

**Evidence:** the live store listings.

## M-12 — Store submission content

**Source:** `tasks/release-checklist.md` (also P6-11..13, PE-06/17/18/27).
**Why only you:** this text is typed into your store accounts, and the review
account must be created on the production backend by you. All the wording is
already drafted in `tasks/release-checklist.md`.

1. Copy the **Release 1.0** subtitle and full description, and the five
   screenshot captions, into both stores. Don't mention GitHub Actions,
   SonarQube, GitLab or CircleCI in the 1.0 listing — they ship in later
   releases. Check the website's home/integrations/pricing pages agree.
2. Paste the **App Review notes**, with the 1.0 substitution
   "This release works with Jenkins only." (details in the checklist).
3. Fill **App Privacy** from the checklist table — Diagnostics → Crash Data:
   collected, **not linked, not tracking** — and Play's **Data safety** form
   from the same file. Re-check `ios/Runner/PrivacyInfo.xcprivacy` (AUD-56).
4. Create the review account on the production backend (a normal account,
   with no saved servers) and put its email and password in the store's own
   fields — never in this repository.
5. Add the demo line to each description: "Try the in-app demo without an
   account or a server."

**Evidence:** screenshots of the completed store fields.

## M-13 — Website go-live

**Source:** P15-22, P15-24 (`tasks/phase-15-website.md`), PE-03
(`tasks/phase-emergency.md`).
**Why only you:** it needs your Vercel account, and the store links don't
exist until the stores are live (M-08/M-09/M-11).

1. Mac: connect the Vercel project and its environment variables
   (`docs/deployment.md`, "Website"). Marketing can go live first; the portal
   waits for the public `https://` backend (M-14).
2. Fill `site-details.ts` (company name, privacy and security emails, reply
   days, backup retention, last-updated date) — `launch-readiness.test.ts`
   lists what's missing.
3. Once the listings are live, set `storeLinks` in `site-links.ts` and add the
   QR code (a pre-built SVG, or a QR library — needs your approval).

**Evidence:** the live site.

## M-14 — Production backend deploy and keys

**Source:** P20-05 (`tasks/phase-20-subscriptions.md`), PE-30, PE-31
(`tasks/phase-emergency.md`).
**Why only you:** production cloud, the secret manager, the production Atlas
cluster and the encryption keys are yours; release builds also refuse an
`http://` backend, so this unlocks TestFlight and the portal.

1. Deploy the backend at a public `https://` URL with a production Atlas
   cluster (`docs/deployment.md`).
2. Put the production encryption key in the host's secret manager (not a
   file), keep a second key id ready for rotation, and record the rotation
   steps in `docs/deployment.md`.
3. Back up, then run `node scripts/encrypt-credentials.js --dry-run` and then
   without `--dry-run`; confirm the startup audit reports no unreadable key
   ids.

**Evidence:** the live `/healthz` over `https://`.

## M-15 — Billing / subscriptions launch

**Source:** Phase 20 — P20-03, P20-05/06 (links), P20-40..42, P20-51..53,
P20-60..63, P20-85; G/H/F sections of `tasks/phase-20-subscriptions.md`.
**Why only you:** store agreements, tax/banking, RevenueCat and Paddle
accounts, sandbox testers and the pricing/conversion decisions are all yours.

1. App Store Connect: Paid Apps agreement, tax, banking (check Sri Lanka
   payout details), subscription group + two products, 7-day trial on yearly,
   Small Business Program enrolment (P20-40).
2. Play Console: payments profile, monthly and yearly base plans, trial on
   yearly (P20-41).
3. RevenueCat: project, both apps, entitlement `pro`, offering `default`,
   webhook URL + secret, sandbox testers (P20-42).
4. Paddle: sandbox account, Pro product with monthly/yearly prices, approved
   payment link domain, webhook to `/api/billing/paddle/webhook`, client-side
   token (P20-85).
5. Transfer behaviour with two real sandbox store accounts (P20-03).
6. iPhone sandbox pass via `scripts/run-on-iphone.sh`: buy, trial, accelerated
   renewal, cancel, restore on a second install, downgrade locking (P20-51);
   the Android pass is part of M-02 (P20-52).
7. Decide whether to commission the third-audit security review of the
   webhook and plan checks (P20-53); staging and TestFlight with
   `BILLING_ENABLED=true` (P20-60), grant Pro to testers (P20-61), production
   flip and announcement (P20-62), conversion review after ~200 paywall views
   (P20-63).

**Evidence:** sandbox purchase/restoration results and the live plan setup.

## M-16 — Firebase server push

**Source:** NR-06b (`tasks/phase-22-next-release.md`). The backend sender is
already built and tested (`npm test` 392 passing).
**Why only you:** it needs your Firebase project, APNs key and the
`google-services.json` / `GoogleService-Info.plist` config files, plus your
approval for the `firebase_messaging` package (CLAUDE.md §3) and for the
architecture change (the server would poll Jenkins with decrypted credentials;
today the phone talks to Jenkins directly).

1. Create the Firebase project, add the iOS and Android apps, generate the
   APNs key and provide the two config files.
2. Approve adding `firebase_messaging`, the token upload on launch and the
   notification-permission prompt.
3. Approve the server-side trigger design, then verify a build-finish push
   arrives on the iPhone.

**Evidence:** a push notification received on the iPhone.

## M-17 — GitHub fallback decision

**Source:** PE-43 (`tasks/phase-emergency.md`). **Only if M-06 finds a
blocking bug and release can't wait.**
**Why only you:** it's a product/release trade-off the owner must decide, not
an engineering default.

1. If the GitHub checks find a blocker, choose whether to ship without
   GitHub Actions: turn it off in `CiTool.isAvailable` and hide the GitHub
   section in the portal for that release.

**Evidence:** your decision, recorded against PE-43.

---

## Held for your signal (agent acts, not an owner task)

- **`SithumRaigamage/jobtrigger-actions-test`** — the throwaway private repo
  used for the live GitHub verification (M-06). I'm keeping it until you say
  the GitHub token check is done; the moment you say so, I delete it with
  `gh repo delete SithumRaigamage/jobtrigger-actions-test`.
