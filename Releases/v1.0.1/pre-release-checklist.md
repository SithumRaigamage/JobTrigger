# Pre-Release Checklist — v1.0.1 (planned)

- [ ] **1. Tool Manifest Synchronisation**: `release/tools.json` unchanged;
  `node scripts/sync-tools.mjs --check` passes.
- [ ] **2. Automated Test Gates**: `flutter analyze` clean, `flutter test`
  green, backend suite green, website `npm run check` and `npm run e2e` green.
- [ ] **3. Team plan switched on**: `TEAM_PLAN_ENABLED="true"` in
  `render.yaml`; `team-plan` is `live` in `feature-status.ts`; `GET /api/team`
  answers for a signed-in user.
- [ ] **4. M-23 done**: Paddle per-seat prices set on the host and a sandbox
  team purchase completed (`manually/M-23-team-plan-paddle.md`).
- [ ] **5. Manual Owner Sign-off**: a team invite accepted on the iPhone and a
  shared Jenkins server used from Settings → Team servers.
