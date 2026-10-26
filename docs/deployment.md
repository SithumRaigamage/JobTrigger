# Deployment (App Store / Play Store) and CI/CD

Written up after a chat discussion on 2026-09-14; the build-verification
step below landed 2026-09-15 as part of `tasks/phase-9-testing-cicd-hardening.md`
(P9-09). Everything blocking an actual store release (accounts, signing,
artwork) is tracked as external/ops action in
[`tasks/release-checklist.md`](../tasks/release-checklist.md); this doc is
the "how," that one is the "what's left."

## Prerequisites (regardless of tooling)

- **Apple**: an Apple Developer Program membership ($99/yr), App Store
  Connect access, a signing certificate + provisioning profile (or let
  Xcode/Fastlane manage them automatically via "automatic signing").
- **Google**: a Play Console account ($25 one-time), and a signing key for
  the app — Play App Signing manages the rest once you upload your first
  upload key.
- Both stores also expect app icons, screenshots, and a privacy policy URL
  — see `tasks/release-checklist.md`'s artwork item, still open.

## The mechanical deploy process, Flutter-side

Every release build passes the environment's config (AUD-43). Without it
the app refuses to start rather than silently talking to the dev backend:

```bash
flutter build appbundle --release --dart-define-from-file=config/prod.json
flutter build ipa --release --dart-define-from-file=config/prod.json
```

- **Android**: `flutter build appbundle --release` (with the flag above) → produces a `.aab` →
  upload to Play Console, start on the **internal testing** track, not
  production.
- **iOS**: `flutter build ipa --release` (with the flag above) → produces an `.ipa` → upload via
  Xcode/Transporter to App Store Connect → starts in **TestFlight**, not
  the public store.

Both stores expect an internal/beta track before public release — matches
`tasks/release-checklist.md`'s existing "Internal TestFlight + Play
internal testing" and "Dogfood window" items.

## CI/CD tooling options

| Option | Tradeoff |
|---|---|
| **GitHub Actions + Fastlane** | Free, full control, matches this repo's existing `.github/workflows/flutter-ci.yml` convention. You write/maintain the signing + upload scripting yourself (Fastlane lanes, App Store Connect API keys, Play service-account JSON as GitHub secrets). |
| **Codemagic** | Flutter-specific SaaS; handles code signing through its UI instead of scripting it, fastest path to an automated store release. Free tier exists. Separate service/account to manage. |
| **Bitrise** | Similar to Codemagic, more general-purpose mobile CI, more setup than Codemagic for a Flutter-only project. |
| **Manual for now** | Upload by hand via Xcode/Play Console once a build exists. Build *verification* is automated (`.github/workflows/cd.yml`), but signing and upload are still manual/nonexistent — see below. |

## What's automated today (P9-09)

`.github/workflows/cd.yml` exists and is invokable from the Actions tab
(`workflow_dispatch` only — it never runs automatically on push/PR, per the
"don't build the deploy pipeline yet" reasoning below, which still holds).
It builds `flutter build apk --release --dart-define-from-file=config/prod.json` (debug-signed, because CI has no
`key.properties`; see "Android release signing" below) and
`flutter build ipa --release --no-codesign` (same config flag), uploading both as
workflow artifacts — nothing is pushed to a store or a registry. A second
job does `docker build` against a new `JobTrigger-Backend/Dockerfile`
(no `push`), verifying the backend still containerizes; no registry is
configured to push it to yet.

This satisfies recommendation #1 below, already done. `.github/workflows/flutter-ci.yml`
itself (the one that actually gates PRs) is deliberately left as
analyze/test-only — build verification lives in the separate,
manually-triggered `cd.yml` instead, so PR CI stays fast.

## Pipeline security controls (P13-18, AUD-59)

| Control | Where | Blocking |
|---|---|---|
| npm advisories (high+) | `nodejs-test.yml` | yes |
| pub + npm advisories (OSV) | `security.yml` `dependencies` | yes |
| Secrets in git history (gitleaks) | `security.yml` `secrets` | yes; reviewed exceptions in `.gitleaksignore` |
| Backend image (Trivy, high+, fixable) | `security.yml` `backend-image` | yes |
| Generated code matches its sources | `flutter-ci.yml` | yes |
| Android and iOS builds compile | `flutter-ci.yml` | yes |
| SonarCloud | `nodejs-test.yml` | informational; skipped until `sonar.projectKey`/`sonar.organization` and `SONAR_TOKEN` are set |

Every workflow runs with `permissions: contents: read`, every action is
pinned to a commit SHA (Dependabot's `github-actions` entry keeps them
current), and the scanners are release binaries checked against their
published checksums. `security.yml` also runs weekly, since new advisories
arrive for code that hasn't changed.

**Owner action:** require the `analyze-and-test`, `build-android`,
`build-ios`, `test` (Node), `secrets`, `dependencies`, and `backend-image`
checks through branch protection on `develop` and `flutter-migration`.
Until then a red check doesn't stop a merge, which is how AUD-42 went
unnoticed for 19 pushes.

## Android release signing (P12-10, AUD-15)

`android/app/build.gradle.kts` signs release builds with the key described
in `JobTrigger-Frontend/android/key.properties`. That file, and every
`*.jks`/`*.keystore`, is git-ignored (`android/.gitignore`). Never commit
them.

1. Create the upload key once and keep it somewhere backed up (outside the
   repo):

   ```bash
   keytool -genkeypair -v -keystore ~/keys/jobtrigger-upload.jks \
     -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Create `JobTrigger-Frontend/android/key.properties`:

   ```properties
   storeFile=/Users/you/keys/jobtrigger-upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```

   `storeFile` may be absolute, or relative to `android/`.

3. `flutter build appbundle --release --dart-define-from-file=config/prod.json`
   (for Play) or the same with `apk`. To check which key signed an APK:
   `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`.

Behaviour, verified 2026-09-30:

- **No `key.properties`:** the release build still succeeds, signed with
  the **debug** key, and Gradle logs `WARNING: android/key.properties not
  found…`. `flutter build` hides Gradle warnings; `./gradlew :app:help`
  shows it. A debug-signed build can't be uploaded to Play.
- **Incomplete `key.properties`:** the build fails immediately with
  `android/key.properties is missing '<field>'` rather than a cryptic
  signing error.
- **Complete:** the release APK carries the upload key's certificate.

With Play App Signing, this key is only the *upload* key: Google re-signs
for distribution, and a lost upload key can be reset through Play Console.
For CI, write `key.properties` and the keystore from GitHub secrets in the
job, never in the repo (recommendation #2 below).

## Backend secrets at rest (P12-26, AUD-03)

Tool credentials are stored AES-256-GCM encrypted. Each environment needs:

- `CREDENTIALS_ENCRYPTION_KEY`: base64 of 32 random bytes, in the secret
  manager next to `JWT_SECRET`. The server refuses to start without a
  valid one.
- `CREDENTIALS_ENCRYPTION_KEY_ID` (optional, default `k1`): stored with
  every value, which is what makes rotation possible.

**First deploy:** set the key, deploy, then run
`npm run encrypt-credentials` (see `database-migrations.md`). Rows stay
readable during the gap.

**Rotation:** generate a new key and give it a new id, e.g. `k2`. Move the
old pair into `CREDENTIALS_ENCRYPTION_PREVIOUS_KEYS=k1:<old base64>`,
deploy, run `npm run encrypt-credentials` to re-encrypt, and drop the old
key once the run reports 0.

Losing the key makes every stored credential unreadable (users would
re-enter them), so back it up like the database.

## Website (`JobTrigger-Web/`, Phase 15)

The Next.js site is its own deploy, separate from the app stores and the
backend. Vercel first (P15-22), Docker later (P15-23). Conventions:
[`web-architecture.md`](web-architecture.md).

### Vercel (P15-22)

**Owner action** — connecting the project needs the owner's Vercel
account; nothing here has been deployed.

1. New project → import this repository → **Root Directory:
   `JobTrigger-Web`**. Vercel detects Next.js; build command `npm run
   build`, no output directory override. Node comes from `engines`
   (`>=24`) and `.nvmrc`.
2. Environment variables, **Production** only (see the table below).
   Leave the portal's two variables unset on Preview deployments: a
   preview then serves marketing pages and shows "server setup isn't
   available" on the portal, rather than talking to the production
   backend from an unreviewed branch.
3. Domain: point the apex/`www` at Vercel and set `SITE_URL` to the
   canonical one. HTTPS and the http→https redirect are Vercel's; the site
   adds HSTS itself (`next.config.ts`).

| Variable | Production value | Notes |
|---|---|---|
| `SITE_URL` | `https://<your domain>` | Canonical URLs, Open Graph, sitemap, robots.txt. Read at request time |
| `JOBTRIGGER_BACKEND_URL` | `https://<backend host>` | Must be `https://` (`config.ts` refuses http outside loopback). **Unset until the backend is deployed** |
| `SESSION_SECRET` | 32+ random characters | Encrypts the session cookie. `node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"`. Rotating it signs everyone out of the website (not the app) |

**Marketing first, portal later.** No backend deployment exists yet
(`config/prod.json` is a placeholder). With the two portal variables
unset, every marketing page works and `/sign-in`, `/sign-up`,
`/servers` and `/account` show "Server setup on the web isn't available
right now" — verified against a production build with no portal env
(2026-10-26). Set both variables once the backend is live at an
`https://` URL; no code change is needed.

What the deploy relies on, all verified locally against `next build &&
next start`:

- The proxy (`src/proxy.ts`) runs on the Node.js runtime, Next 16's
  default for proxies; it sets the per-request CSP nonce, so every page is
  rendered per request (`web-architecture.md` "Security headers").
- `robots.txt` and `sitemap.xml` are rendered per request, so `SITE_URL`
  set in Vercel is what they print (a build-time render printed
  `http://localhost:3000`; fixed in P15-22, and the e2e build now runs
  without `SITE_URL` to catch the class).
- The Open Graph image is generated at build time from the bundled Inter
  Bold; it reads no environment variable.

Before promoting a deployment, run the local gate (`npm run check` and
`npm run e2e` in `JobTrigger-Web/`) — GitHub Actions is off, so these are
the merge gate.

## Recommendation

Don't build the full auto-deploy pipeline yet — the project is pre-artwork
and pre-store-accounts (`tasks/release-checklist.md`), so wiring signing
secrets into CI now would be premature; there's nothing to sign with. One
thing left worth doing once relevant:

1. ~~Extend CI with a `flutter build apk`/`flutter build ipa --no-codesign`
   step~~ — done, see above.
2. Once both store accounts and real signing keys exist, add a
   Fastlane-based deploy job (GitHub Actions is the natural fit given
   what's already here) targeting internal/TestFlight tracks only,
   matching `tasks/release-checklist.md`'s existing plan.
