# Google Play release runbook — v1.0.0 (first release)

This is the focused, step-by-step guide for the **first Google Play
production release** of JobTrigger 1.0.0. Billing is **enabled** in this
release. iOS is out of scope here.

- **Application ID:** `com.sraig.jobtrigger`
- **Version:** `1.0.0` (`versionName`), `1` (`versionCode`, from `pubspec.yaml` `1.0.0+1`)
- **Shipped tools:** Jenkins, SonarQube, GitHub Actions
- **Prices:** $9.99/month, $29.99/year (7-day yearly trial)

---

## Local state (already done on this Mac)

- [x] Release keystore generated: `JobTrigger-Frontend/android/app/upload-keystore.jks`
  - alias `upload`, password stored in git-ignored `android/key.properties`
  - **Back up both files — losing them means you can never update the app.**
- [x] Version files aligned (Flutter `1.0.0+1`, backend/web `1.0.0`)
- [x] `node scripts/sync-tools.mjs --check` passes
- [x] `flutter analyze` clean; full test suite green
- [x] Docs updated for billing-enabled + new prices

## Secrets still required before a store build

`scripts/build-release.sh appbundle` refuses to build a store bundle unless
these are present (put them in the git-ignored files or export them):

| Secret | Where | Notes |
|---|---|---|
| `SENTRY_DSN` | `config/sentry.json` | GlitchTip DSN; errors only |
| `REVENUECAT_ANDROID_KEY` | `config/billing.json` | RevenueCat **public** Android key (`goog_…`) |

Backend `.env` (production): `BILLING_ENABLED=true`,
`REVENUECAT_SECRET_API_KEY`, `REVENUECAT_WEBHOOK_AUTH`. Play products and the
`pro` entitlement must exist in RevenueCat (see
`docs/subscription/sandbox-testing.md`).

---

## Step 1 — Build the release App Bundle

Once the secrets are in place:

```bash
scripts/build-release.sh --check appbundle   # validate config, no build
scripts/build-release.sh appbundle           # real signed build
```

Output: `JobTrigger-Frontend/build/app/outputs/bundle/release/app-release.aab`

For an unsigned verification build without keys (does not ship):
```bash
scripts/build-release.sh --allow-missing appbundle
```

**Verified 2026-11-18:** `--allow-missing appbundle` produced a signed
`app-release.aab` (~72 MB) with the `upload` certificate
(`CN=JobTrigger, OU=Mobile, O=JobTrigger, L=Colombo, ST=Western, C=LK`,
SHA-256 `6E:39:D3:D1:C7:64:4E:86:DB:DB:C3:4E:8A:EC:69:E5:47:C1:2B:B6:A0:8E:BF:B7:38:29:A4:03:28:4D:4E:81`).
That verification build has **no Sentry and no RevenueCat key**, so it has
no subscription UI — the real store build must be rebuilt with the secrets.
A Gradle lint error in
`android/app/src/main/res/xml/data_extraction_rules.xml` (invalid
`<device-config><files>` schema) was fixed to the valid Android 12+
`<cloud-backup>`/`<device-transfer>` schema so release builds pass.

> Toolchain note: `flutter doctor` reports the Android **cmdline-tools**
> component missing, so native debug symbols were not stripped from the AAB
> (hence ~72 MB). Upload still works — Play strips server-side — but install
> cmdline-tools via Android Studio SDK Manager before the final build so
> symbol stripping succeeds and Play gets native debug symbols.

## Step 2 — Verify the bundle locally

```bash
# Inspect the AAB (bundletool, if installed)
java -jar bundletool.jar validate \
  --bundle=JobTrigger-Frontend/build/app/outputs/bundle/release/app-release.aab

# Confirm signing (should show the 'upload' certificate)
jarsigner -verify -verbose -certs \
  JobTrigger-Frontend/build/app/outputs/bundle/release/app-release.aab | head
```

## Step 3 — Google Play Console setup

1. Sign in to https://play.google.com/console (the $25 one-time fee account).
2. **All apps → Create app**
   - Name: `JobTrigger`
   - Default language: English (US)
   - App or game: App
   - Free or paid: **Free** (subscriptions are IAP)
   - Declare: you are the owner, no coded penal interests, etc.
3. Fill the **Store listing**:
   - Short description: `Jenkins, GitHub Actions and SonarQube builds, on your phone.`
   - Full description: from `tasks/release-checklist.md`
   - Screenshots: 7 images from `release/store-screenshots/android-2by1/`
   - Feature graphic, 512×512 icon (from `scripts/export-icons.sh`)
   - Category: Developer Tools / Productivity
   - Website: `https://jobtrigger.app` and a support email
4. **App content** questionnaire:
   - Data safety (answers in `tasks/release-checklist.md`)
   - Content rating questionnaire → submit
   - Target audience & content (family-safe apps rules)
   - Privacy policy URL: `https://jobtrigger.app/privacy` (site must be live)
5. **Monetize → Products → Subscriptions**:
   - Product `jobtrigger-pro`, base plans: Monthly $9.99, Yearly $29.99
     with 7-day free trial. Attach to RevenueCat entitlement `pro`.
6. **Setup → License testing**: add your tester Google accounts (not charged).

## Step 4 — Upload & test (Internal Testing first)

1. **Testing → Internal testing → Create new release** → upload `app-release.aab`.
2. Add release name/notes (from `Releases/v1.0.0/release-notes.md`).
3. Roll out to internal testers. Install from Play and verify on a real device:
   - Sign in as `tester@jobtrigger.app` / `TesterPass123!`; it starts **Free**
   - Subscribe monthly and yearly (license testers are not charged)
   - Cancel in Play → Pro stays until period end → becomes Free
   - **Resubscribe** from the Subscription screen while it is still active
   - Restore purchases; switch servers on Free (only one stays unlocked)

   If the store products or the RevenueCat key are not ready yet, test the
   same loop first with the development sandbox (no payment): run the backend
   with `BILLING_ENABLED=true SANDBOX_BILLING=true` and build with
   `SANDBOX_BILLING=1 scripts/run-flutter.sh --target=android-device`. See
   `docs/subscription/sandbox-testing.md` Part D. The sandbox is never in a
   store build.
4. Fix anything found, bump `versionCode` if you must re-upload (e.g. `1.0.0+2`).

## Step 5 — Production rollout

1. **Testing → Internal testing → Promote to Production** (or create a new
   production release from the same AAB after sign-off).
2. Choose **staged rollout** (start at 10%, watch crash-free rate and
   RevenueCat events, then ramp to 100%).
3. Complete any remaining **Release dashboard** declarations if prompted.

## Step 6 — Post-release (`post-release.md`)

- Watch GlitchTip for new errors and RevenueCat for purchase/conversion events.
- Verify `GET https://api.jobtrigger.app/healthz` stays healthy.
- Record the exact upload time, rollout % and any hotfix in
  `Releases/v1.0.0/post-release.md`.

---

## Blockers / owner actions (external, cannot be done from code)

- [ ] Google Play Console account active ($25 paid)
- [ ] Store listing assets, privacy policy URL live on the website
- [ ] Data safety / content rating / target audience answers signed off
- [ ] `SENTRY_DSN` and `REVENUECAT_ANDROID_KEY` supplied
- [ ] Backend production deployed with `BILLING_ENABLED=true` + RevenueCat secrets
- [ ] Play products + RevenueCat `pro` entitlement configured
