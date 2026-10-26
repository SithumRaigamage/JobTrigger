# Phase 18 — iPhone testing on the local network

Goal: make testing on a physical iPhone, with the backend and Jenkins
running on the developer's Mac, a documented one-command flow. On the phone,
`127.0.0.1` is the phone itself, so the app needs the Mac's Wi-Fi address,
and that address changes with the network.

Requested by the owner on 2026-10-26 after installing the app on their
iPhone ("add a guide … in the root or somewhere its accessible easily … this
configurations but configurable"), on branch `feat/iphone-lan-testing`.

## Decisions approved with the phase (2026-10-26)

1. **The guide is `IPHONE.md` in the repository root**, linked from the
   README's Getting Started and from `docs/dev-setup.md`, whose iPhone
   section becomes a pointer so the steps live in one place.
2. **The address is detected, not typed.** `scripts/run-on-iphone.sh`
   finds the Mac's Wi-Fi IP, writes the git-ignored `config/device.json`,
   checks the backend answers there, picks the connected iPhone and runs
   `flutter run --profile`. `BACKEND_HOST`, `BACKEND_PORT`, `DEVICE`,
   `MODE` and `SKIP_BACKEND_CHECK` override each guess. `release` is
   refused: it rejects an `http://` backend by design (AUD-43).
3. **Jenkins: guide steps only.** `IPHONE.md` gives the `docker run`
   command (`-p 8080:8080`, a `jenkins_home` volume) and the Jenkins URL
   setting. The repository's test Jenkins (`tools/jenkins-fixture/`) stays
   localhost-only.
4. **Tracked as its own phase** (this file), with its own PR.

## Tasks

- [x] P18-01 `scripts/run-on-iphone.sh` and the `config/device.json`
      git-ignore entry.
- [x] P18-02 `IPHONE.md`: phone and Xcode setup, backend, install, first
      launch, Jenkins in Docker reachable from the phone, address changes,
      troubleshooting, security notes. Links from `README.md`,
      `docs/dev-setup.md` and `config/README.md`.

## Outcome (2026-10-26)

- **Checked on the owner's Mac:** the script detected `192.168.1.24`,
  wrote `device.json`, and the backend answered at that address
  (`/healthz`). Overrides, the `release` refusal and the "no iPhone"
  message were run; the iPhone picker was checked against sample
  `flutter devices` output (one phone among a simulator and the Mac, only
  a simulator, two phones, unreadable output).
- **Not run here:** an install on the phone itself (no iPhone was
  connected); the owner runs `scripts/run-on-iphone.sh` with it plugged in.
