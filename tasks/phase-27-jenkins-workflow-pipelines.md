# Phase 27 — Jenkins workflow pipeline mirrors

Source: owner request, 2026-11-19 — "convert the GitHub workflows into
Jenkins files and create them in `Jenkins/`, keep the workflows GitHub
unchanged."

Goal: every job/stage of the GitHub Actions CI/CD is mirrored as a
Declarative Jenkinsfile under `Jenkins/`, so the same build gates exist on
the Jenkins side JobTrigger manages, without touching `.github/workflows/`.

The GitHub workflows stay exactly as they are; the Jenkinsfiles are mirrors,
not replacements. The live CI remains GitHub Actions until the owner moves a
pipeline to Jenkins on purpose.

## Layout (decided 2026-11-19)

One Jenkinsfile per GitHub workflow, in `Jenkins/<workflow>/Jenkinsfile`:

| Jenkinsfile | Mirrors | Jobs / stages |
|---|---|---|
| `Jenkins/backend/Jenkinsfile` | `.github/workflows/nodejs-test.yml` + backend job of `cd.yml` | checkout, npm ci, audit, test:coverage, Codecov upload, SonarCloud scan, backend docker build |
| `Jenkins/frontend/Jenkinsfile` | `.github/workflows/flutter-ci.yml` (+ the release builds that `cd.yml` adds for the Flutter app, covered by `Jenkins/release/Jenkinsfile`) | checkout, INTERNET manifest check, release-build-config check, format, analyze, build_runner freshness, tests, coverage, build debug apk, build iOS debug (develop-only) |
| `Jenkins/website/Jenkinsfile` | `.github/workflows/web-ci.yml` | checkout, node 22, npm ci, runtime audit, lint/typecheck/format, unit tests, Playwright, e2e |
| `Jenkins/security/Jenkinsfile` | `.github/workflows/security.yml` | gitleaks history scan, OSV lockfile scan, trivy backend image, backend image build |
| `Jenkins/release/Jenkinsfile` | `.github/workflows/cd.yml` | flutter-build (Android release apk + iOS release unsigned + uploads), backend-docker-build |
| `Jenkins/tools/Jenkinsfile` | `.github/workflows/tools-manifest.yml` | node 22, `node --test scripts/*.test.mjs`, `sync-tools.mjs --check` |

Jenkinsfiles use Declarative syntax (`pipeline { agent … stages { stage …
{ steps … } } }`), `options { timestamps() }`, per-stage agents (Docker
images / macOS label), and `checkout scm`. The existing fixture style under
`tools/jenkins-fixture/sample-repo/pipelines/` is the house style these
mirrors follow.

## Conventions and flags

- **No shared library** is introduced in this phase; each Jenkinsfile is
  self-contained so a mirror can be reviewed file by file.
- **Secrets**: Jenkins credentials (`withCredentials`, `withSonarQubeEnv`,
  Codecov token id `codecov-token`, SonarQube server id `sonar`). Two values
  are marked *owner input* until wired: the Codecov token credentials id and
  the SonarQube server/credentials id names.
- **Branch filtering**: `build-ios` in the frontend pipeline mirrors the
  workflow's condition — runs only on push to `develop` and on manual runs.
- **Docker**: backend stages run in `node:22-alpine` containers, image build in
  `docker:27`; Flutter stages in `ghcr.io/flutter/flutter:stable`; iOS on a
  macOS agent.

## Verification

- Jenkins container (`jenkins/jenkins:lts-jdk21`, present locally) started;
  the pipeline definitions parse and the jobs can be created from them.
- `.github/workflows/` unchanged (diff must stay empty for those files).
- No Jenkins server / fixture state was modified for this phase.

## Risks / follow-ups

- Real Jenkins run of these pipelines (agent labels, credentials, SonarQube
  server) needs the owner to point them at the lab Jenkins — an owner action,
  not code.
- If the owner prefers, the mirrors can be consolidated later into a shared
  library or a single root `Jenkinsfile`.
