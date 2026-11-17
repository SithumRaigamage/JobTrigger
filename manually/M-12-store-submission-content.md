# M-12 — Store submission content

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** `tasks/release-checklist.md` (also P6-11..13, PE-06/17/18/27).
**Why only you:** this text is typed into your store accounts, and the review
account must be created on the production backend by you. All the wording is
already drafted in `tasks/release-checklist.md`.

1. Copy the **Release 1.0** subtitle and full description, and the seven
   screenshot captions, into both stores. Release 1.0 ships Jenkins, SonarQube
   and GitHub Actions; don't mention GitLab CI or CircleCI in the listing —
   they are planned for 1.3. Check the website's home/integrations/pricing
   pages agree.
2. Paste the **App Review notes** unchanged (all three tools are available in
   1.0; details in the checklist).
3. Fill **App Privacy** from the checklist table — Diagnostics → Crash Data:
   collected, **not linked, not tracking** — and Play's **Data safety** form
   from the same file. Re-check `ios/Runner/PrivacyInfo.xcprivacy` (AUD-56).
4. Create the review account on the production backend (a normal account,
   with no saved servers) and put its email and password in the store's own
   fields — never in this repository.
5. Add the demo line to each description: "Try the in-app demo without an
   account or a server."

**Evidence:** screenshots of the completed store fields.
