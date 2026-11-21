# Releases Directory

This directory is the single source of truth for release lifecycle management, GitFlow tracking, and version sign-offs in JobTrigger.

---

## Release Index

| Version | Release Date | Target Branch | Status | Shipped Tools | Reference |
|---|---|---|---|---|---|
| **v1.0.0** | TBD (was 2026-11-17) | `main` (not cut) | **Development-complete — deployment and store steps pending** | Jenkins, SonarQube, GitHub Actions | [`v1.0.0/workplan.md`](./v1.0.0/workplan.md) · [`release-notes`](./v1.0.0/release-notes.md) |
| *v1.0.1* | Planned | `main` | Draft: turns on the team plan | Jenkins, SonarQube, GitHub Actions | [`v1.0.1/release-notes.md`](./v1.0.1/release-notes.md) |
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
   # Add the release checklist page (same HTML for every release):
   cp tools/release-checklist/release-checklist.html Releases/vX.Y.Z/
   # then write Releases/vX.Y.Z/checklist-data.js for this release
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
├── post-release.md             # Smoke test records, error/GlitchTip monitoring, and hotfixes
├── release-checklist.html      # The checklist page: an unchanged copy of tools/release-checklist/release-checklist.html
└── checklist-data.js           # This release's tasks for that page (the only file that differs per release)
```

### Release checklist page

Every release folder gets `release-checklist.html` and `checklist-data.js`.
Open the HTML by double-clicking it (no build, no internet). How it works and
the data format: [`tools/release-checklist/README.md`](../tools/release-checklist/README.md).

**Keep it in sync:** whenever a task moves (done, newly needed, or no longer
needed), update `checklist-data.js` in the same change: set `done: true`
rather than deleting a finished task, and never reuse a task id. Ticks made in
the browser live only in that browser; use **Export ticks** and give the JSON
to Claude to record them in the data file.
