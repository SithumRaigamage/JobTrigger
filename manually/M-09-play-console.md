# M-09 — Play Console internal testing

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P6-11. **Why only you:** a Play Console account and the Android
upload signing key are yours alone (`docs/deployment.md`, "Android release
signing", P12-10).

1. Mac: `flutter build appbundle --release --dart-define-from-file=config/prod.json`
   (signed via `android/key.properties`).
2. Upload the `.aab` to Play Console → Testing → Internal testing; complete
   the Data safety form from the table in `tasks/release-checklist.md`.

**Evidence:** the release is available to internal testers.
