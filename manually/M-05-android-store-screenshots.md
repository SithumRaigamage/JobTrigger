# M-05 — Android store screenshots (DONE 2026-11-17)

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P6-07 (`tasks/phase-6-polish-release.md`). No longer an owner task:
captured directly this session; record kept here for the release trail.
**What was done:** installed the missing Android NDK (r28c, SHA-1 verified),
booted the `Medium_Phone_API_37.0` emulator at 1080×2160, and captured seven
matching shots in demo mode with
`integration_test/store_screenshots_test.dart` (five Jenkins, one GitHub
repositories, one SonarQube projects). The capture test was made
cross-platform (one surface conversion at the start on Android, a no-op on
iOS). Output is seven JPEGs without alpha in
`release/store-screenshots/android-2by1/`, each exactly 1080×2160 (Google
Play's 2:1 limit); the taller iPhone 6.9" shots can't be reused. Captions and
the retake command are in `docs/store-submission.md`.
**Evidence:**
`release/store-screenshots/android-2by1/{01-jobs,02-folder,03-job,04-failing-job,05-build-log,06-github-repos,07-sonar-projects}.jpg`.
No owner action remains for this item.
