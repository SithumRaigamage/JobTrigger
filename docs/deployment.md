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

- **Android**: `flutter build appbundle --release` → produces a `.aab` →
  upload to Play Console, start on the **internal testing** track, not
  production.
- **iOS**: `flutter build ipa --release` → produces an `.ipa` → upload via
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
It builds `flutter build apk --release` (debug-signed, since
`android/app/build.gradle`'s release build type has no real signing config
yet) and `flutter build ipa --release --no-codesign`, uploading both as
workflow artifacts — nothing is pushed to a store or a registry. A second
job does `docker build` against a new `JobTrigger-Backend/Dockerfile`
(no `push`), verifying the backend still containerizes; no registry is
configured to push it to yet.

This satisfies recommendation #1 below, already done. `.github/workflows/flutter-ci.yml`
itself (the one that actually gates PRs) is deliberately left as
analyze/test-only — build verification lives in the separate,
manually-triggered `cd.yml` instead, so PR CI stays fast.

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
