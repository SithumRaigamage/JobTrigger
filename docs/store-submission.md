# Store submission pack (release 1.0, Jenkins only)

Everything needed to submit is prepared here or linked. Only the upload itself
needs the owner's store accounts; those steps are in `tasks/MANUAL.md`.

| Piece | Where |
|---|---|
| App icons and launch screen | Done (Phase 16); regenerate with `scripts/export-icons.sh` |
| Screenshots (iPhone 6.9", 1320×2868, no alpha) | `release/store-screenshots/ios-6.9/` — taken from the iOS simulator in demo mode |
| Store text, per release | `tasks/release-checklist.md`, "Store listing text" → "Release 1.0" |
| App Store privacy answers and Play Data safety | `tasks/release-checklist.md`, "App Store privacy answers" |
| App Review notes (demo walkthrough) | `tasks/release-checklist.md`, "App Review notes" |
| Crash-reporting rules and verification | `docs/error-reporting.md` |
| Android signing | `docs/deployment.md`, "Android release signing" |

## Screenshot captions (iPhone, in this order)

| File | Caption |
|---|---|
| `01-jobs.jpg` | Your Jenkins jobs, on your phone |
| `02-folder.jpg` | Browse folders, branches and pull requests |
| `03-job.jpg` | See the last build and its stages, then trigger a new one |
| `04-failing-job.jpg` | Spot what failed at a glance |
| `05-build-log.jpg` | Read the console and jump to the first error |

Each shows the in-app banner "Demo: sample data, nothing here is real". The
shots mention only Jenkins, as release 1.0 requires. To retake them:

```bash
cd JobTrigger-Frontend
SCREENSHOT_DIR=../release/store-screenshots/ios-6.9 flutter drive \
  --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/store_screenshots_test.dart \
  -d <6.9-inch simulator id> --dart-define-from-file=config/dev.json
# the driver writes PNGs with an alpha channel; the App Store wants none:
for f in ../release/store-screenshots/ios-6.9/*.png; do
  sips -s format jpeg -s formatOptions 95 "$f" --out "${f%.png}.jpg" && rm "$f"; done
```

Android phone screenshots are not in this pack: they need an Android emulator,
which needs the NDK (`tasks/MANUAL.md`). An iPhone 6.9" image is taller than
Google Play's 2:1 limit, so it can't be reused there.

## Pre-flight (all on the Mac, before building)

```bash
cd JobTrigger-Frontend
dart run build_runner build --delete-conflicting-outputs
flutter analyze            # must be clean
flutter test               # must be all green
# version: bump `version:` in pubspec.yaml (name+build), e.g. 1.0.0+2
```

`config/prod.json` must hold the production backend's `https://` URL and the
public keys (RevenueCat, Sentry DSN); a release build refuses an `http://`
backend (`app_config.dart`). Never commit a DSN or key.

## Archive and upload — iOS

```bash
cd JobTrigger-Frontend
flutter build ipa --release --dart-define-from-file=config/prod.json
# -> build/ios/ipa/*.ipa (needs the Apple Distribution certificate and profiles)
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  --apiKey <APP_STORE_CONNECT_KEY_ID> --apiIssuer <ISSUER_ID>
# or drag the .ipa into the Transporter app
```

Then in App Store Connect: select the build under TestFlight (internal group),
and for release attach it to version 1.0, add the screenshots and text above,
the privacy answers, the review notes and the review account.

## Archive and upload — Android

```bash
cd JobTrigger-Frontend
flutter build appbundle --release --dart-define-from-file=config/prod.json
# -> build/app/outputs/bundle/release/app-release.aab, signed with the upload
#    key from android/key.properties (docs/deployment.md)
```

Upload the `.aab` to Play Console → Testing → Internal testing, complete the
Data safety form from `release-checklist.md`, add screenshots, then promote.

## Checked in this environment

- `flutter build ios --release --no-codesign --dart-define-from-file=config/prod.json`
  builds (see `tasks/phase-6-polish-release.md`, P6-11). Signing, upload and
  review need the owner's accounts.
