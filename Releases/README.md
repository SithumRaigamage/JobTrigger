# Releases Directory

This directory is the single source of truth for release lifecycle management, GitFlow tracking, and version sign-offs in JobTrigger.

---

## Release Index

| Version | Release Date | Target Branch | Status | Shipped Tools | Reference |
|---|---|---|---|---|---|
| **v1.0.0** | 2026-11-17 | `main` | **Pre-Release / Staged** | Jenkins, SonarQube, GitHub Actions | [`v1.0.0/`](./v1.0.0/release-notes.md) |
| *v1.1.0* | Planned | `main` | Draft | Jenkins, SonarQube, GitHub Actions | — |
| *v1.3.0* | Planned | `main` | Future | + GitLab CI, CircleCI | — |

---

## GitFlow Release Workflow

1. **Cut Release Branch**:
   When feature work is frozen on `develop`, branch off:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/vX.Y.Z
   ```

2. **Initialize Release Folder**:
   Create a new release tracking folder from the template:
   ```bash
   mkdir -p Releases/vX.Y.Z
   # Copy and fill template files:
   cp Releases/TEMPLATE.md Releases/vX.Y.Z/
   # (or populate release-notes.md, pre-release-checklist.md, deployment-log.md, post-release.md)
   ```

3. **Verify Tool Manifest Sync**:
   Verify that `release/tools.json` and its copies across Frontend, Web, and Backend are identical:
   ```bash
   node scripts/sync-tools.mjs --check
   ```

4. **Sign-off Pre-Release Checklist**:
   Execute all items in `Releases/vX.Y.Z/pre-release-checklist.md`.

5. **Merge & Tag**:
   Merge `release/vX.Y.Z` into both `main` and `develop`:
   ```bash
   # Merge to main and tag
   git checkout main
   git merge release/vX.Y.Z
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin main --tags

   # Back-merge to develop
   git checkout develop
   git merge release/vX.Y.Z
   git push origin develop
   ```

6. **Hotfixes (`hotfix/vX.Y.Z`)**:
   Branch off `main`, test, log in `post-release.md`, tag, and merge back to both `main` and `develop`.

---

## Directory Layout Per Version

```
Releases/vX.Y.Z/
├── release-notes.md            # User-facing features, tools enabled, and limitations
├── deployment-instructions.md  # Sequential execution instructions across GitHub, Backend, Web, and Android
├── pre-release-checklist.md    # Automated tests, manifest sync, store screenshots & privacy sign-offs
├── deployment-log.md           # Exact build commands, environment configs, and deploy records
└── post-release.md             # Smoke test records, error/GlitchTip monitoring, and hotfixes
```
