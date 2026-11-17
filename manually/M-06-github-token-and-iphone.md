# M-06 — GitHub fine-grained token and iPhone checks

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P8-26, P8-27 (`tasks/phase-8-github-actions.md`), PE-41, PE-42.
**Done already (2026-11-17):** the live API half through the app's own client
against the real throwaway repo `SithumRaigamage/jobtrigger-actions-test`
(three workflows: with inputs, no inputs, disabled) — repos and workflows
listed, dispatch with inputs queued, runs/jobs/steps/logs/history read; an
invalid token is an `AuthFailure` kept apart from permission failures.
**Why only you:** a fine-grained personal access token cannot be created
through the API — only you can create it in GitHub's settings — and the final
walk-through is on your iPhone.

1. Mac: GitHub → Settings → Developer settings → Personal access tokens →
   Fine-grained tokens → create one with read + Actions write, scoped to
   `SithumRaigamage/jobtrigger-actions-test`.
2. Phone: install with `scripts/run-on-iphone.sh`, add the GitHub credential
   with that token, and confirm a GitHub 401 keeps the backend session and the
   Jenkins/SonarQube clients alive.
3. Phone: walk all three workflows in the app — list them, dispatch the one
   with inputs, open a run, its jobs and steps and logs, then run history.
4. When you're done with the token check, tell me so I can delete the
   throwaway repo (see "Held for your signal" at the bottom).

**Evidence:** note + screenshots of the 401 isolation and the run walk-through.
