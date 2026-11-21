# Manual (owner) tasks — one draft per task

Every item that only the owner can close has its own draft file in this
folder. This is the single place to look for what still needs you, what to do,
and why nobody else can do it. `tasks/MANUAL.md` points back here so older
links keep working.

**Nothing here can be closed by an agent:** each needs a physical device you
own, an account only you hold, a credential that must never enter this
repository, a real-world/public action, or a business decision. The code and
the prepared commands are already done. When you finish one, tell me which
`M-XX` it was and what you saw; I'll tick the source task(s) and update the
tracker.

**Your iPhone is the test device (CLAUDE.md §10):** install with
`scripts/run-on-iphone.sh`, and anything the phone reaches runs on the Mac's
Wi-Fi address (get it with `ipconfig getifaddr en0`; it changes with the
network). Use the Mac's local hostname `Sithums-MacBook-Pro.local` if the IP
changes; `IPHONE.md` covers both.

| Id | Task | Source | On hold? |
|---|---|---|---|
| [M-01](M-01-physical-iphone-relaunch.md) | Kill-and-relaunch on the physical iPhone | P2-11 | no |
| [M-02](M-02-android-on-device-jank.md) | Android on-device log jank test | P5-13, P11-03 | **yes — no Android device** |
| [M-03](M-03-sonarqube-iphone-auth.md) | SonarQube iPhone auth + real-server pass | P10-14, P10-15, P20-07 | no |
| [M-04](M-04-sonarcloud-account.md) | SonarCloud account and organization | P10-15 | no |
| [M-06](M-06-github-token-and-iphone.md) | GitHub fine-grained token + iPhone checks | P8-26, P8-27, PE-41, PE-42 | no |
| [M-07](M-07-crash-reporting-dsn.md) | Crash-reporting DSNs + iPhone test crash | P6-08, PE-19d/e | no |
| [M-08](M-08-app-store-connect.md) | App Store Connect / TestFlight | P6-11 | no |
| [M-09](M-09-play-console.md) | Play Console internal testing | P6-11 | no |
| [M-10](M-10-dogfood-window.md) | Dogfood window | P6-12 | after M-08/M-09 |
| [M-11](M-11-public-release.md) | Public release | P6-13 | after M-10 |
| [M-12](M-12-store-submission-content.md) | Store text, privacy answers, review notes | release-checklist.md | before M-08/M-09 |
| [M-13](M-13-website-go-live.md) | Website go-live | P15-22, P15-24, PE-03 | after M-08/M-09 |
| [M-14](M-14-production-backend.md) | Production backend deploy + keys | P20-05, PE-30, PE-31 | no |
| [M-15](M-15-billing-launch.md) | Billing / subscriptions launch | Phase 20 | no |
| [M-16](M-16-firebase-push.md) | Firebase server push | NR-06b | approval needed |
| [M-17](M-17-github-fallback.md) | GitHub fallback decision | PE-43 | only if M-06 finds a blocker |
| [M-18](M-18-support-tickets-iphone.md) | Support tickets on the iPhone | P25-01..06 | no |
| [M-19](M-19-production-mail.md) | Production mail: provider, sender, support and student inboxes | US-AUTH-08, Phase 21 | no — Student Plan ships in 1.0 |
| [M-20](M-20-atlas-network-lockdown.md) | Lock down Atlas network access (remove `0.0.0.0/0`) | deployment.md, RD-04 | no — **do now** |
| [M-21](M-21-discord-community.md) | Discord community server | audit 2026-11-20 | optional for 1.0 |
| [M-22](M-22-replay-with-edits-live.md) | Replay with edits on your real Jenkins | P11-29, US-JX-16 | no |
| [M-23](M-23-team-plan-paddle.md) | Team plan: Paddle per-seat prices + sandbox purchase | P28-04, US-SUB-11 | release 1.0.1 |

## Resolved

- [M-05](M-05-android-store-screenshots.md) — Android store screenshots:
  **DONE 2026-11-17** (7 images, 1080×2160, in
  `release/store-screenshots/android-2by1/`). Kept for the record only.

- The throwaway `SithumRaigamage/jobtrigger-actions-test` repo used for the
  live GitHub verification (M-06) was deleted by the owner on 2026-11-17.
