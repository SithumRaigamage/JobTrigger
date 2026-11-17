# M-08 — App Store Connect / TestFlight

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


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
