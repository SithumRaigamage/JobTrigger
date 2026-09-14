# Deployment (App Store / Play Store) and CI/CD

Not yet implemented — this is reference material for when the app is ready
to submit, written up after a chat discussion on 2026-09-14. Everything
blocking an actual store release (accounts, signing, artwork) is tracked as
external/ops action in [`tasks/release-checklist.md`](../tasks/release-checklist.md);
this doc is the "how," that one is the "what's left."

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
| **Manual for now** | Build locally, upload by hand via Xcode/Play Console. What this project effectively does today — see `.github/workflows/flutter-ci.yml`, which only runs `flutter analyze`/`flutter test`, no build/sign/upload step. |

## Recommendation

Don't build the full auto-deploy pipeline yet — the project is pre-artwork
and pre-store-accounts (`tasks/release-checklist.md`), so wiring signing
secrets into CI now would be premature; there's nothing to sign with. Two
things worth doing once relevant:

1. Extend `.github/workflows/flutter-ci.yml` with a `flutter build apk`/
   `flutter build ipa --no-codesign` step — catches "doesn't actually
   build for release" regressions early, no store accounts needed.
2. Once both store accounts and real signing keys exist, add a
   Fastlane-based deploy job (GitHub Actions is the natural fit given
   what's already here) targeting internal/TestFlight tracks only,
   matching `tasks/release-checklist.md`'s existing plan.
