# M-16 — Firebase server push

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** NR-06b (`tasks/phase-22-next-release.md`). The backend sender is
already built and tested (`npm test` 392 passing).
**Why only you:** it needs your Firebase project, APNs key and the
`google-services.json` / `GoogleService-Info.plist` config files, plus your
approval for the `firebase_messaging` package (CLAUDE.md §3) and for the
architecture change (the server would poll Jenkins with decrypted credentials;
today the phone talks to Jenkins directly).

1. Create the Firebase project, add the iOS and Android apps, generate the
   APNs key and provide the two config files.
2. Approve adding `firebase_messaging`, the token upload on launch and the
   notification-permission prompt.
3. Approve the server-side trigger design, then verify a build-finish push
   arrives on the iPhone.

**Evidence:** a push notification received on the iPhone.
