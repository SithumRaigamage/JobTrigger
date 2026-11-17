# M-02 — Android on-device log jank test

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P5-13 (`tasks/phase-5-build-execution-logs-history.md`), P11-03
(`tasks/phase-11-jenkins-extended.md`). Also covers the Android half of P20-52.
**On hold — you have no Android device.**
**Done already:** a 50,000-line host test (`console_log_viewer_50k_test.dart`)
decodes in under 5 s, keeps under 200 live `RichText` widgets after 20 flings,
and `jumpToLine` reaches the error marker; the fixture Jenkins `big-log` job is
ready. That proves the virtualization mechanism, not real device frame times.
**Why only you:** the task explicitly asks for a mid-range Android device, and
there is none here. I installed the missing NDK (r28c) and ran the new
`integration_test/android_log_jank_test.dart` on the `Medium_Phone_API_37.0`
emulator on 2026-11-17: it passed (virtualization holds, no throw) and
recorded 1,566 frames at p50 18.4 ms / p95 171.1 ms / worst 1423 ms (software
GPU) and 1,614 frames at p50 15.2 ms / p95 36.8 ms / worst 985 ms
(swiftshader). Those emulator numbers are not a clean 60 fps pass and an
emulator is not a mid-range phone, so this stays open — the real device is the
measurement the task asks for.

1. Mac: use the prepared `Medium_Phone_API_37.0` emulator (NDK r28c is now
   installed) or a real device, and build the profile APK.
2. Mac: start the fixture Jenkins `big-log` job (50,000 lines).
3. Android device: add the Jenkins server using the Mac's Wi-Fi address, not
   `localhost`; open the failing build's console log and fling-scroll it.
4. With Developer Options → GPU/frame-time profiling on, record frame times
   and confirm no sustained dropped frames over the 50k-line log.
5. For P20-52, also do the Android Play license-tester sandbox pass ([M-15](M-15-billing-launch.md)).

**Evidence:** the frame-time recording / note, and the sandbox result.
