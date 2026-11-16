# Release manifest

`tools.json` is the one answer to "which tools does this build support".

```json
{ "release": "1.0", "tools": { "jenkins": "1.0", "sonarqube": "1.1", "githubActions": "1.2" } }
```

- `release` is the release being built. Each tool carries the release it ships in.
- A tool is **released** when its version is less than or equal to `release`
  (numbers, so `1.10` is after `1.2`). Released tools can be selected, saved
  and used. The others are shown as "Coming next" with their version.
- Planned tools with no code yet (`gitlab`, `circleci`) are allowed while their
  release is ahead. A tool whose release has come must have code
  (`IMPLEMENTED` in `scripts/tools-manifest.mjs`), or the script refuses it.
- The version is only a label for the plan: move a tool to another release by
  editing this one file.

## Changing it

1. Edit `release/tools.json`.
2. Run `node scripts/sync-tools.mjs`. It validates the file and copies it,
   byte for byte, to `JobTrigger-Frontend/config/tools.json`,
   `JobTrigger-Web/src/content/tools.json` and `JobTrigger-Backend/config/tools.json`.
3. Commit all four files.

CI (`.github/workflows/tools-manifest.yml`) runs `node --test scripts/` and
`node scripts/sync-tools.mjs --check`; each project also has a test that its
copy equals the source.

Tests in the app, website and backend run with an all-tools manifest so tools
hidden in a release stay tested.

## How each project reads it

- **App** (`lib/domain/tools/tool_catalog.dart`): a tool is available when it is
  implemented *and* released. GitLab CI and CircleCI have no code, so even a
  manifest that releases them cannot make them selectable.
- **Website** (`src/content/release.ts`): the integrations page, the portal's
  tool picker and the feature-status labels ("Coming in 1.2"). End-to-end
  builds swap in `tests/e2e/all-tools.json` (`E2E_ALL_TOOLS=1`, Playwright only).
- **Backend** (`lib/releasedTools.js`): creating a credential for a tool the
  release doesn't ship answers `403 TOOL_NOT_AVAILABLE`. Reads, updates and
  deletes are never blocked.

The manifest calls GitHub Actions `githubActions`; the website's `Tool` type and
the backend's routes and stored data call it `github`. Each project maps manifest
ids to its own ids in one place (`MANIFEST_TO_TOOL`, `LOCAL_TOOL`); nothing is
renamed, and an id a project doesn't know fails loudly.
