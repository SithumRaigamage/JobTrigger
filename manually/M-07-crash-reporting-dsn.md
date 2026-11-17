# M-07 — Crash-reporting DSNs and iPhone test crash

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


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
