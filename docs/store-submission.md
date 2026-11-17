# Store submission pack (release 1.0, Jenkins + SonarQube + GitHub Actions)

Everything needed to submit is prepared here or linked. Only the upload itself
needs the owner's store accounts; those steps are in
[`manually/`](../manually/README.md) (M-08, M-09, M-12).

| Piece | Where |
|---|---|
| App icons and launch screen | Done (Phase 16); regenerate with `scripts/export-icons.sh` |
| Screenshots (iPhone 6.9", 1320×2868, no alpha) | `release/store-screenshots/ios-6.9/` — taken from the iOS simulator in demo mode |
| Screenshots (Android 2:1, 1080×2160, no alpha) | `release/store-screenshots/android-2by1/` — taken from the `Medium_Phone_API_37.0` emulator in demo mode |
| Store text, per release | `tasks/release-checklist.md`, "Store listing text" → "Release 1.0" |
| App Store privacy answers and Play Data safety | `tasks/release-checklist.md`, "App Store privacy answers" |
| App Review notes (demo walkthrough) | `tasks/release-checklist.md`, "App Review notes" |
| Crash-reporting rules and verification | `docs/error-reporting.md` |
| Android signing | `docs/deployment.md`, "Android release signing" |

Release 1.0 ships all three built tools — Jenkins, SonarQube and GitHub
Actions — so the pack has screenshots for each. GitLab CI and CircleCI are
planned for 1.3 and must not be mentioned in the 1.0 listing, screenshots or
keywords.

## Screenshot captions (iPhone, in this order)

| File | Caption |
|---|---|
| `01-jobs.jpg` | Your Jenkins jobs, on your phone |
| `02-folder.jpg` | Browse folders, branches and pull requests |
| `03-job.jpg` | See the last build and its stages, then trigger a new one |
| `04-failing-job.jpg` | Spot what failed at a glance |
| `05-build-log.jpg` | Read the console and jump to the first error |
| `06-github-repos.jpg` | Watch GitHub Actions runs across your repositories |
| `07-sonar-projects.jpg` | Check SonarQube quality gates, issues and trends |

Each shows the in-app banner "Demo: sample data, nothing here is real". The
Jenkins shots are the five-workflow walkthrough; the GitHub and SonarQube
shots are each tool's Home list (the sample data is fixed in demo mode). To
retake them, run the capture test once per `SHOT_TOOL`:

```bash
cd JobTrigger-Frontend
SIM=3E612B39-2081-4DE2-AFC8-1BF759302D48   # 6.9-inch simulator
for tool in jenkins github sonarqube; do
  SCREENSHOT_DIR=../release/store-screenshots/ios-6.9 flutter drive \
    --driver=test_driver/screenshot_driver.dart \
    --target=integration_test/store_screenshots_test.dart \
    -d "$SIM" --dart-define-from-file=config/dev.json \
    --dart-define=SHOT_TOOL=$tool
done
# the driver writes PNGs with an alpha channel; the App Store wants none:
for f in ../release/store-screenshots/ios-6.9/*.png; do
  sips -s format jpeg -s formatOptions 95 "$f" --out "${f%.png}.jpg" && rm "$f"; done
```

## Screenshot captions (Android, in this order)

The same seven screens as iOS, in `release/store-screenshots/android-2by1/`
(each 1080×2160, Google Play's 2:1 limit, JPEG without alpha). The captions in
the table above apply unchanged. The iPhone 6.9" image is taller than Play's
2:1 limit, so the two platforms need separate sets. To retake the Android set:

```bash
# One-time: install Android NDK r28c into $ANDROID_HOME/ndk/28.2.13676358
# (Flutter/AGP provisions this automatically; r28c is the pinned revision).
cd JobTrigger-Frontend
flutter emulators --launch Medium_Phone_API_37.0
# Emulator must be 1080x2160 (Play's 2:1 limit):
adb shell wm size 1080x2160
for tool in jenkins github sonarqube; do
  SCREENSHOT_DIR=../release/store-screenshots/android-2by1 flutter drive \
    --driver=test_driver/screenshot_driver.dart \
    --target=integration_test/store_screenshots_test.dart \
    -d emulator-5554 --dart-define-from-file=config/dev.json \
    --dart-define=SHOT_TOOL=$tool
done
# Convert the driver's PNGs to alpha-free JPEGs:
for f in ../release/store-screenshots/android-2by1/*.png; do
  sips -s format jpeg -s formatOptions 95 "$f" --out "${f%.png}.jpg" && rm "$f"; done
```

The capture test converts the Flutter surface to an image once at the start
(`convertFlutterSurfaceToImage()`), which is a no-op on iOS — so the same test
produces both platform packs.

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
- All seven screenshots in both packs were captured in demo mode on the
  iPhone 18 Pro Max simulator and the `Medium_Phone_API_37.0` emulator, then
  verified at the correct dimensions (1320×2868 and 1080×2160).
