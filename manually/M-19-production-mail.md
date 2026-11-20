# M-19 — Production mail: provider, sender and owner inbox

> Added by the pre-release audit (2026-11-20). Back to the [index](README.md).

**Source:** US-AUTH-08 (password reset), Phase 21 SP-2/SP-22 (student
email code and the new-application notice), `Releases/v1.0.0/release-notes.md`
("Password reset: built but not switched on").
**Why only you:** a mail provider account, a verified sending domain (DNS)
and the inboxes are yours.

Without SMTP in production the backend still answers `202` and logs
`mail.disabled`: password reset, the student email-code path and your
"new student application" notice silently send nothing. The Student Plan
ships in 1.0, so this is needed for it to work for anyone without a document.

1. Pick a provider (Resend, Postmark, Amazon SES or similar) and verify the
   sending domain (SPF, DKIM, DMARC records on `jobtrigger.app`).
2. Create the inboxes: `support@jobtrigger.app` (the app's Contact support
   and the website's support page — the backend now derives it from
   `SITE_URL`, or set `SUPPORT_EMAIL`) and the one that gets student
   applications.
3. In the host's secret manager set `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`,
   `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM` (e.g. `JobTrigger
   <no-reply@jobtrigger.app>`; production now refuses a missing or `.local`
   sender), `RESET_PASSWORD_URL=https://jobtrigger.app/reset-password` and
   `STUDENT_ADMIN_EMAIL`.
4. Decide whether password reset goes live in 1.0. If yes, mark it live on
   the website (the sign-in link currently goes to support) and update the
   release notes; tell me and I'll make the change.
5. Re-seed AppInfo after `SITE_URL` is set (`node scripts/seedAppInfo.js`)
   so the support address matches the domain.

**Evidence:** a reset email and a student code email received at a real
inbox from the production backend, and the student notice in your inbox.
