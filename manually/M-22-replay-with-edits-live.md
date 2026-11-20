# M-22 — Replay with edits on a real Jenkins (US-JX-16)

> Added 2026-11-20 with US-JX-16. Back to the [index](README.md).

**Source:** P11-29 (`tasks/phase-11-jenkins-extended.md`), US-JX-16.
**Why only you:** it runs pipeline code on your Jenkins, from your iPhone.

The HTTP contract was verified on the fixture Jenkins 2.568.3 (P11-27) and
every criterion has automated tests; this is the one live pass.

1. On the Mac: in your Jenkins, have an inline pipeline job (Pipeline →
   Definition: **Pipeline script**) with at least one build.
2. On the iPhone (`scripts/run-on-iphone.sh`): open the job → **History** →
   the replay icon on a build → **Replay with edits…**.
3. Check the script shown is the job's script, edit one `echo`, tap
   **Replay** → **Continue** → type the job name → **Replay**.
4. The app opens the new build; its console shows your edited `echo` and
   its cause reads "Replayed #N".
5. Repeat on a job whose Definition is **Pipeline script from SCM**: the
   screen says the Jenkinsfile comes from a repository.

**Evidence:** the new build's number and its "Replayed #N" cause.
