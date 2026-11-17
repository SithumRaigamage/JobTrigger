# M-17 — GitHub fallback decision

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** PE-43 (`tasks/phase-emergency.md`). **Only if [M-06](M-06-github-token-and-iphone.md) finds a
blocking bug and release can't wait.**
**Why only you:** it's a product/release trade-off the owner must decide, not
an engineering default.

1. If the GitHub checks find a blocker, choose whether to ship without
   GitHub Actions: turn it off in `CiTool.isAvailable` and hide the GitHub
   section in the portal for that release.

**Evidence:** your decision, recorded against PE-43.

---

## Held for your signal (agent acts, not an owner task)

- **`SithumRaigamage/jobtrigger-actions-test`** — the throwaway private repo
  used for the live GitHub verification ([M-06](M-06-github-token-and-iphone.md)). I'm keeping it until you say
  the GitHub token check is done; the moment you say so, I delete it with
  `gh repo delete SithumRaigamage/jobtrigger-actions-test`.
