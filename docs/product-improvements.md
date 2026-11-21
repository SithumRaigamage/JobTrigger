# JobTrigger — Product Improvements (beyond CI/CD tools)

Written 2026-11-16. A **proposal list**, not a plan of record: nothing here
is promoted. Status of record stays in `tasks/README.md`.

This list covers ways to make JobTrigger better **other than adding more
CI/CD tools** (those are in `docs/future-tools.md`). It has **168
improvements** across the app, the website and the backend.

## Already planned, so not repeated here

These are in `docs/implemented/improvement-plan.md` and are not counted below: the
unified home dashboard, jump to first error and log folding, server push
notifications, QR-code pairing, clearer error copy, team workspaces, AI
summaries of why a build failed, flaky-test detection, iPad layout, Apple
Watch alerts, localisation, an audit log of who triggered what, and
multi-account support.

## How to read the tables

- **Size:** S = up to 2 days, M = up to 2 weeks, L = more than 2 weeks.
- **Flags** say what approval an item needs before work starts:
  - *New package* — a dependency outside the locked stack (`CLAUDE.md` §3).
  - *Backend* — backend work, a separate track (`CLAUDE.md` §7).
  - *Jenkins frozen* — changes Jenkins code, which is frozen (§11); it
    needs the owner to reopen it, or it is built for the other tools first.
  - *New scope* — not in the feature matrix (§7).

Every item still goes through plan, design and approval (§9) when it is
picked up.

## A. Everyday use

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-01 | **Global search** across all tools: jobs, repositories, SonarQube projects, in one search bar | People remember a name, not which tool or server it is on | M | New scope |
| IMP-02 | **Groups for pinned items** ("Release", "Nightly", "Client A"), with drag to reorder | Pinned jobs get crowded once someone uses more than one tool | S | — |
| IMP-03 | **Parameter presets**: save named sets of parameters per job ("Staging deploy", "Hotfix") | Typing the same five values on a phone is slow and error-prone | M | Jenkins frozen |
| IMP-04 | **Run again with the same parameters** from any history row | The most common action after a failure is "try that again" | S | Jenkins frozen |
| IMP-05 | **Recently viewed** list on the home screen | Fast way back to what you were looking at on the laptop | S | — |
| IMP-06 | **Swipe actions** in lists: pin, cancel, rerun, share | One-handed use | S | — |
| IMP-07 | **App icon shortcuts** (iOS Quick Actions, Android app shortcuts): open a pinned job, open the last failure | Two taps from the home screen to the thing you need | S | New package |
| IMP-08 | **Siri Shortcuts and Android App Actions**: "Trigger nightly build" with a confirm step | Hands-free, and works with automations people already use | M | New package |
| IMP-09 | **Scheduled triggers** set from the phone ("run this at 02:00") | Useful for off-hours jobs without editing the pipeline | L | Backend, New scope |
| IMP-10 | **List density setting** (comfortable / compact) | Power users want more rows per screen | S | — |

## B. Notifications and alerts

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-11 | **Notification rules** per watched item: failures only, "back to green" only, main branch only | Too many alerts makes people turn them all off | M | — |
| IMP-12 | **Quiet hours** with an override for chosen jobs | Respects sleep, keeps the alerts that matter | S | — |
| IMP-13 | **Actions inside the notification**: Open log, Rerun, Mute this job | Handles most alerts without opening the app | M | — |
| IMP-14 | **iOS Live Activities and Dynamic Island** for a running build | Watch a deploy on the lock screen without opening the app | L | New package, needs native extension |
| IMP-15 | **Daily digest**: one summary notification ("3 failed, 12 passed yesterday") | Low-noise alternative to per-build alerts | M | — |
| IMP-16 | **Chat delivery** of alerts to Slack, Microsoft Teams or Discord webhooks, set up on the website | Teams already live in chat; the phone becomes one of several outputs | M | Backend |
| IMP-17 | **Email alert fallback** for failures, using the existing mailer | Works when push is off or the phone is away | S | Backend |

## C. Logs and debugging

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-18 | **Compare with last green build**: show what changed (commits, parameters, duration, first differing log section) | Most failures are explained by "what's different from yesterday" | M | — |
| IMP-19 | **Known-error hints**: an offline rule list that spots common errors (out of memory, dependency conflict, disk full, expired token) and shows a short fix hint | Fast help without AI or network | M | — |
| IMP-20 | **Pretty view** for JSON, XML and stack traces inside logs, with collapse | Phone screens make raw dumps unreadable | M | — |
| IMP-21 | **Share a line range** of a log as text with the build link | "Look at lines 210–240" is what people paste into chat | S | — |
| IMP-22 | **Timestamps toggle** and time spent per log section | Find the slow step | S | — |
| IMP-23 | **Landscape log viewer** with adjustable font size | Long lines need width | S | — |

## D. Security and privacy

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-24 | **Two-step confirm for production actions**: deploy, rollback, flag toggle, cancel on protected jobs; optional "type the name to confirm" | A phone in a pocket is the easiest place to tap the wrong thing | S | — |
| IMP-25 | **Read-only mode per server**: hide trigger and cancel | Lets people safely add production servers just to watch them | S | — |
| IMP-26 | **Two-factor authentication** (authenticator app codes) for the JobTrigger account | The account holds tokens to many systems; a password alone is weak | M | Backend |
| IMP-27 | **Passkeys** for sign-in on the app and the website | Phishing-resistant and faster than passwords | L | Backend, New package |
| IMP-28 | **Signed-in devices** list with remote sign-out | Lost phone recovery; builds on the existing `tokenVersion` | M | Backend |
| IMP-29 | **Token expiry reminders** (for example GitHub fine-grained tokens) | Stops the "it worked yesterday" support ticket | S | — |
| IMP-30 | **Token scope checker**: warn when a token has more rights than JobTrigger needs | Least privilege, and a good trust message | M | — |
| IMP-31 | **Hide content in the app switcher** on screens that show secrets or logs | Logs can contain sensitive data | S | — |
| IMP-32 | **Custom certificate authority** support for on-prem servers with an internal CA | Many company Jenkins servers use an internal CA; today that means "can't connect" | M | — |
| IMP-33 | **Download my data** on the website (servers without secrets, settings, plan history) | Privacy rights and user trust | M | Backend |
| IMP-34 | **Rooted / jailbroken device warning** (warn, don't block) | Secure storage is weaker there; users should know | M | New package |

## E. Reaching servers behind firewalls

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-35 | **"Why can't I reach it?" check**: tells apart wrong URL, private address on mobile data, VPN off, certificate error | The most common first-run failure for self-hosted Jenkins | M | — |
| IMP-36 | **In-app guides** for Tailscale, WireGuard and Cloudflare Tunnel, linked from that check | Turns a dead end into a fix (expands `docs/remote-access.md`) | S | — |
| IMP-37 | **Relay agent** (research): a small open-source agent inside the company network that connects out, so the phone never needs inbound access | Unlocks enterprises that will never expose Jenkins | L | Backend, New scope — changes the "no backend proxy" rule in `CLAUDE.md` §1, needs an architecture decision |

## F. Performance and reliability

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-38 | **Last updated time and offline banner** on every data screen | People must know whether a green tick is fresh | S | — |
| IMP-39 | **Conditional requests** (ETag / If-None-Match) where the API supports them, starting with GitHub | Faster, and saves rate limit | M | — |
| IMP-40 | **Rate-limit meter** for GitHub and other limited APIs | Explains slowdowns before they become errors | S | — |
| IMP-41 | **Battery saver**: slower polling when the phone is in low-power mode | Live polling is the app's biggest battery cost | S | — |
| IMP-42 | **Startup and scroll performance budgets** checked in tests | Keeps the app fast as tools are added | M | — |
| IMP-43 | **App size reduction** (unused icons, assets, split per ABI on Android) | Smaller download, more installs on slow networks | S | — |

## G. Platforms and devices

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-44 | **Lock-screen widgets** (iOS) and more Android widget sizes | Status at a glance without unlocking | M | — |
| IMP-45 | **Android tablet and foldable layouts** (two panes) | Android side of the planned iPad work | M | — |
| IMP-46 | **Wear OS** tile with pinned job status | Android side of the planned Apple Watch work | L | New scope, needs native code |
| IMP-47 | **macOS desktop build** with a menu-bar status icon | Same code base; many users are on a Mac all day | L | New scope |
| IMP-48 | **In-app review prompt** after a good moment (first successful trigger), never after an error | Store ratings drive installs | S | New package |
| IMP-49 | **Consistent haptics** for success, failure and destructive confirm | Feedback without looking | S | — |

## H. Accessibility

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-50 | **Full VoiceOver and TalkBack pass** with fixes on every screen | Required for an inclusive app, and store featuring favours it | M | — |
| IMP-51 | **Status by shape and text, not colour alone** (icon plus label everywhere) | Colour-blind users can't tell red from green dots | S | — |
| IMP-52 | **Large text layouts** tested at the biggest system sizes | Logs and lists break first at large sizes | S | — |
| IMP-53 | **Respect Reduce Motion** for live progress animations | Comfort for motion-sensitive users | S | — |

## I. Insights

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-54 | **DORA metrics** per project: deployment frequency, lead time, change failure rate, time to restore | The language engineering managers already use | L | New scope |
| IMP-55 | **"My week" report**: builds triggered, failures fixed, time saved | A reason to open the app weekly, and shareable | M | — |
| IMP-56 | **CI minutes and cost view** for hosted tools (GitHub Actions minutes first) | Money is a strong reason to check a phone | M | New scope |
| IMP-57 | **Quality trend** for SonarQube: coverage and new issues over time on one chart | Turns SonarQube data into a story | M | — |

## J. AI help (beyond the planned failure summaries)

All AI features must say what is sent where, be optional, and never send
secrets. Logs are scrubbed first, like crash reports
(`docs/error-reporting.md`).

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-58 | **Ask the log**: a question box on the log screen ("why did the tests fail?") | Long logs on a small screen are the app's hardest problem | L | Backend, New scope |
| IMP-59 | **Explain this issue** for SonarQube findings in plain words, with an example fix | Helps juniors and students act on findings | M | Backend, New scope |
| IMP-60 | **Pipeline file explainer** for a Jenkinsfile or workflow YAML | People inherit pipelines they didn't write | M | Backend, New scope |
| IMP-61 | **Self-hosted model option** (an Ollama endpoint the user owns) for teams that can't send logs to a cloud AI | Privacy-sensitive companies; fits the owner's home lab | L | New scope |
| IMP-62 | **Natural-language trigger** ("deploy staging with version 1.4") that fills the form and always asks to confirm | Fast, but never acts without a tap | L | New scope |

## K. Website and setup portal

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-63 | **Read-only build view on the website** for people without the app | Lets a manager open a shared link | L | New scope |
| IMP-64 | **Bulk add servers** (several Jenkins servers in one form, or CSV) | Agencies and consultants manage many | M | — |
| IMP-65 | **"What's new" sheet** in the app and a public changelog page | Users see progress; fewer "does it do X yet?" questions | S | — |
| IMP-66 | **Searchable help centre** on the website (setup guides per tool, troubleshooting) | Cuts support email | M | — |
| IMP-67 | **Account security page**: devices, 2FA, recent sign-ins | Home for IMP-26 and IMP-28 | M | Backend |

## L. Backend and operations

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-68 | **Public status page** fed by a backend health check | Users check it before emailing support | S | — |
| IMP-69 | **Metrics endpoint** scraped by the owner's Prometheus and Grafana lab | See problems before users do | M | Backend, New package |
| IMP-70 | **Backup and restore drill** for the Atlas database, written up and repeated each quarter | A backup you haven't restored is a guess | S | — |
| IMP-71 | **Remote config / staged rollout** of risky features to a percentage of users | Safer releases | M | Backend |
| IMP-72 | **Versioned API** (`/v1`) before the first public release | Old app versions keep working after backend changes | M | Backend |
| IMP-73 | **Load test** of the backend before launch (sign-in, credential list, webhooks) | Know the limits of the Render plan | S | — |

## M. First-run experience

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-74 | **First-run checklist**: connect a server → trigger a build → turn on alerts | Shows value in the first five minutes | S | — |
| IMP-75 | **Token wizards** that open each tool's token page with the right scopes pre-filled where the tool allows it | Token creation is where most people give up | S | — |
| IMP-76 | **Guided tour inside demo mode** | Demo mode already exists (Emergency E2); a tour turns it into a sales pitch | S | — |

## N. Everyday use (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-77 | **Multi-select bulk actions**: cancel several queued builds, pin or mute many items at once | Cleaning up a stuck queue one item at a time is painful | M | — |
| IMP-78 | **Branch and pull-request filter** on history for every tool | Most people care about one branch at a time | S | — |
| IMP-79 | **"Only mine" filter**: builds I triggered or that contain my commits | Cuts the noise in shared projects | M | — |
| IMP-80 | **Saved filters** with a name ("Prod failures this week") | Reuse the views people build | S | — |
| IMP-81 | **Open any CI link**: paste or share a URL from any supported tool and land on the right screen | Extends Jenkins deep links (US-JX-19) to every tool | M | — |
| IMP-82 | **Copied-link suggestion**: offer to open a CI link found on the clipboard, only after the user allows it | Fast path from chat to the build | S | — |
| IMP-83 | **Calendar heatmap** of builds and failures per day | Patterns are easier to see than in a list | M | — |
| IMP-84 | **Time zone choice** for timestamps (phone or server) | Teams across time zones read times differently | S | — |
| IMP-85 | **Undo** for pin, unpin, mute and remove | Mis-taps on a phone are common | S | — |
| IMP-86 | **Private notes on a build** ("flaky, ignore", "waiting on infra") | Remember context without another app | M | Backend |
| IMP-87 | **Labels for servers** (prod, staging, client name) with filters | Order once people have many servers | S | — |
| IMP-88 | **Environment colour**: a clear production marker in the header on prod servers | Makes it obvious when you are about to touch production | S | — |
| IMP-89 | **Quick server switcher**: long-press the header to jump between servers | Fewer taps for multi-server users | S | — |

## O. Notifications (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-90 | **Re-alert** if a production failure is not opened within a set time | Important alerts shouldn't be lost in a busy lock screen | M | — |
| IMP-91 | **Snooze** a job's alerts for an hour, a day or until it is green | Stops noise during a known outage | S | — |
| IMP-92 | **Group notifications** per tool and per server | A busy morning becomes one stack, not twenty banners | S | — |
| IMP-93 | **Critical alerts** for chosen production jobs (iOS critical alert permission) | Breaks through Do Not Disturb for real emergencies | M | Needs Apple entitlement approval |
| IMP-94 | **Sound per severity** | Know how urgent it is without looking | S | — |
| IMP-95 | **Approvals inbox**: Jenkins input steps, GitHub environment approvals and future CD approvals in one list | Approvals are the most phone-friendly action there is | M | — |
| IMP-96 | **In-app notification history** | Find the alert you swiped away | M | — |

## P. Logs and debugging (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-97 | **Search across past builds** of a job ("when did this error first appear?") | Finds the build that introduced a failure | L | — |
| IMP-98 | **Follow-tail toggle** with a "jump to latest" button | Read earlier lines without being pulled down | S | — |
| IMP-99 | **Word wrap toggle** and a choice of monospace font | Long lines and personal readability | S | — |
| IMP-100 | **Custom highlights**: user-set words or patterns to highlight in every log | Teams have their own warning markers | M | — |
| IMP-101 | **Group test failures by error message** | Fifty failures with one cause become one item | M | — |
| IMP-102 | **Timing waterfall** of pipeline stages and steps | Shows where the time goes | M | — |
| IMP-103 | **Mask known secret patterns** in logs before showing or sharing them | Leaked tokens in logs are common; sharing spreads them | M | — |

## Q. Security (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-104 | **Extra unlock for production servers** (biometric again before an action) | Higher bar for the riskiest actions | S | — |
| IMP-105 | **Auto-lock timeout** choices for the app lock | Balance safety and convenience | S | — |
| IMP-106 | **Warning for `http://` servers** on untrusted networks | Basic auth over plain HTTP on café Wi-Fi exposes passwords | S | — |
| IMP-107 | **New sign-in email** when the account is used on a new device | Early warning of account takeover | S | Backend |
| IMP-108 | **Breached password check** at sign-up and password change (k-anonymity range lookup) | Stops reused leaked passwords | M | Backend |
| IMP-109 | **Session length setting** for the account | Companies have their own policies | S | Backend |
| IMP-110 | **Security checkup screen**: 2FA, expiring tokens, `http://` servers, app lock off | One place to see and fix weak spots | M | — |

## R. Data and sync

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-111 | **Sync settings across devices**: pins, groups, notification rules | A new phone should feel the same | M | Backend |
| IMP-112 | **Export and import settings** as a file, never including secrets | Backup and moving between accounts | S | — |
| IMP-113 | **Safe edits from two devices**: warn when a server was changed elsewhere | Avoids silent overwrites | M | Backend |
| IMP-114 | **Offline cache for the other tools** (GitHub runs, SonarQube projects), like the Jenkins tree cache | Same airplane-mode experience everywhere | M | — |

## S. Platforms and devices (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-115 | **Material You colours** option on Android | Feels native on modern Android | S | — |
| IMP-116 | **Alternative app icons** (iOS and Android) | Small delight; good Pro perk | S | — |
| IMP-117 | **Spotlight search** for pinned jobs on iOS | Find a job from the system search | M | New package |
| IMP-118 | **Android Quick Settings tile** showing status of a pinned job | One swipe from anywhere | M | Native code |
| IMP-119 | **Universal Links** so build links open the app on iPhone and the website on a laptop | Smooth hand-off between devices | M | — |
| IMP-120 | **Android split-screen and multi-window** support | Read a log next to chat | S | — |
| IMP-121 | **Keyboard shortcuts** with an external keyboard on iPad and Android tablets | Power users on tablets | S | — |
| IMP-122 | **Windows and Linux desktop builds** | Same code, more places to use it | L | New scope |

## T. Accessibility (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-123 | **High-contrast theme** | Readability in sunlight and for low vision | S | — |
| IMP-124 | **Readable font option** for people with dyslexia | Logs are dense text | S | — |
| IMP-125 | **Switch Control and keyboard navigation** tested on every screen | Users who can't use touch | M | — |
| IMP-126 | **Sound and haptic status cues** as an option | Status without needing to see colour | S | — |

## U. Insights (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-127 | **Time to green** per job: how long failures stay broken | A simple health measure anyone understands | M | — |
| IMP-128 | **Slowest jobs list** | Where to spend speed-up effort | S | — |
| IMP-129 | **Failure heatmap by hour and weekday** | Reveals nightly or Monday problems | M | — |
| IMP-130 | **Queue wait trends** | Shows when more agents or runners are needed | M | — |
| IMP-131 | **Agent and node usage chart** | Capacity planning from the phone | M | Jenkins frozen |
| IMP-132 | **Weekly email report** | Insights for people who don't open the app | M | Backend |
| IMP-133 | **Export insights** as CSV or PDF | For reports to managers and clients | M | — |

## V. AI help (more)

Same rules as section J: optional, explained, secrets scrubbed first.

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-134 | **Smart alert ranking**: which failures are new and which are the usual flaky ones | Attention goes to what matters | L | New scope |
| IMP-135 | **Likely culprit commit** for a failure, from changes since the last green build | Speeds up "who do I ask?" | L | New scope |
| IMP-136 | **Incident note draft** from a failed deployment: timeline, logs, what was rolled back | Saves the writing after an outage | M | Backend, New scope |
| IMP-137 | **Read my builds aloud** status summary | Hands-free check while commuting | M | New scope |
| IMP-138 | **Same failure as before** detection across builds | Stops re-debugging a known issue | M | New scope |

## W. Website and portal (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-139 | **Browser notifications** from the website for people at a desk | Alerts where they already are | M | Backend |
| IMP-140 | **Connection history graph** per server in the portal | Shows if a server is often unreachable | M | Backend |
| IMP-141 | **Personal API keys** so users can read their own status from scripts | Power users automate everything | L | Backend, New scope |
| IMP-142 | **Webhook receiver**: tools push events to the backend instead of the phone polling | Faster alerts and less battery; also needed for server push | L | Backend, New scope |
| IMP-143 | **Status badge** for a README that links to the build in JobTrigger | Free promotion on every repository that uses it | M | Backend |
| IMP-144 | **Per-tool setup wizard with screenshots** in the portal | Makes token creation foolproof | M | — |

## X. Backend and operations (more)

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-145 | **Abuse and rate-limit dashboard** in the owner's Grafana | See attacks and misuse early | M | Backend |
| IMP-146 | **Retention policy automation**: warn and then delete long-inactive accounts | Less stored personal data, lower risk | M | Backend |
| IMP-147 | **Region choice or a closer region** for the database and backend | Lower latency for users in Asia | L | Backend |
| IMP-148 | **Scheduled key rotation** for credential encryption, using the existing rotation script | Rotation that actually happens | S | — |
| IMP-149 | **Automatic dependency updates** (Dependabot or Renovate) for app, website and backend | Security fixes land without manual checks | S | — |
| IMP-150 | **SBOM for every release** | Customers and auditors ask for it | S | — |
| IMP-151 | **Funnel analytics** in Umami (sign-up → first server → first trigger) | Shows where new users drop off | S | — |

## Y. Plans and purchases

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-152 | **Plan comparison screen** that shows exactly what Free includes | People upgrade when limits are clear, not hidden | S | — |
| IMP-153 | **Gift Pro** to another person | Easy present, and growth | M | Backend |
| IMP-154 | **One-time "lifetime" option test** for people who dislike subscriptions | Some developers only buy once | M | Owner decision |
| IMP-155 | **Renewal reminder** a week before a yearly plan renews | Fewer angry refunds | S | Backend |
| IMP-156 | **Pause instead of cancel** for website subscriptions | Keeps people who are only between projects | M | Backend |

## Suggested first ten

Small, high value, no new packages:
IMP-24 production confirm, IMP-25 read-only servers, IMP-35 reachability
check, IMP-36 tunnel guides, IMP-38 last-updated banner, IMP-11 notification
rules, IMP-74 first-run checklist, IMP-75 token wizards, IMP-51 status by
shape, IMP-65 what's new.

**Promoted 2026-11-17** to `tasks/phase-23-product-improvements.md` as
PI-01…PI-10 (owner-approved). Their status of record is that phase file and
`tasks/README.md`; this section is kept as the proposal's rationale.

## Z. Session continuity and release polish (added 2026-11-19)

These twelve came out of the 1.0.0 readiness review, where the release notes
and the closed feature set were read together with everyday phone use. Four of
them (IMP-157, IMP-158, IMP-160, IMP-163) need no new package, no backend
change and no Jenkins change: IMP-158 keeps the screen awake through a small
platform channel rather than `wakelock_plus`. The owner approved those four on
2026-11-19 as the first 1.1.0 batch, `tasks/phase-26-polish.md`
(`P26-01…P26-04`). The other eight stay proposals here.

| ID | Improvement | Why it matters | Size | Flags |
|---|---|---|---|---|
| IMP-157 | **"Since you last looked" card**: builds that failed, went green or are waiting for approval since the previous app open | The app should answer "what happened while I was away" in one glance, not by scrolling three feeds | S | — |
| IMP-158 | **Deploy-watch mode**: keep the screen awake with a compact running-build pill while a release runs, and exit automatically when it finishes | Watching a deploy means the screen sleeps every 30 seconds and you miss the result | S | — |
| IMP-159 | **Cancel superseded runs**: one action that cancels earlier still-running builds of the same branch or workflow | Morning queues are full of runs nobody wants any more; cancelling them one at a time is the worst kind of phone work | M | — |
| IMP-160 | **Duration estimate beside Trigger**: "last time this took 12 min", with a warning when the job is running far slower than usual | Stops someone starting a 40-minute job five minutes before they have to leave | S | — |
| IMP-161 | **Inline artifact preview** for images, PDF, HTML, JSON and text | Artifacts are a download/share action today; a failed visual-diff screenshot should just open | M | — |
| IMP-162 | **Offline action queue**: a trigger or cancel queued while offline, sent when connectivity returns, stamped with when it was actually sent | Lifts and basements drop the network mid-trigger and the action is simply lost | M | — |
| IMP-163 | **Runbook link per job**: attach a wiki page or checklist that shows before a protected trigger | Every production deploy has a runbook; it should be one tap from the confirm button | S | — |
| IMP-164 | **Shareable trigger templates**: a link that opens the parameter form pre-filled ("deploy staging, version 1.4") | Teammates send "run it like this" in chat; pasting five parameters by hand is the friction | M | New scope |
| IMP-165 | **Job health score**: pass rate, median duration, flake rate and time-to-green as one number per job | A reason to open the app weekly, and a defensible Pro feature | M | — |
| IMP-166 | **Server health warning**: flag an old Jenkins core or a missing plugin that a screen depends on | Turns a confusing empty screen into "your server needs an update" | S | — |
| IMP-167 | **Screenshot on a support ticket**, attached to the existing diagnostics report | A screenshot is what people actually send; text diagnostics alone leave support guessing | S | Backend |
| IMP-168 | **Restart a pipeline from the failed stage**, where the server exposes stage restart | Re-running a 40-minute pipeline to fix its last two minutes is the most common waste in CI | M | Jenkins frozen |

Relationship to earlier items, so nothing is double-counted: IMP-157 differs
from IMP-15 (a scheduled daily digest) and IMP-55 ("my week") by being a
per-session delta. IMP-159 is a rule, not a selection, so it does not replace
IMP-77 (multi-select bulk actions). IMP-160 gives the pre-trigger signal that
IMP-18 (compare with last green) gives after the build. IMP-163 is distinct
from IMP-86 (private notes on a build): the runbook belongs to the job and is
read **before** acting. IMP-168 builds on replay, which already exists.

