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
