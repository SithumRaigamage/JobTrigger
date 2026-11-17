# M-03 — SonarQube iPhone auth isolation and real-server pass

> Draft task file split from `tasks/MANUAL.md`. Back to the [index](README.md). Each M-XX has one file here so it can be worked, ticked and archived independently.


**Source:** P10-14, P10-15 (`tasks/phase-10-sonarqube.md`), P20-07, PE-41/42's
SonarQube half.
**Done already:** automated isolation tests plus the live HTTP check against
the lab server (a bad token and no token both get 401 from
`api/components/search_projects`). The lab SonarQube 26.1.0 is up at
`192.168.1.53:9000`, bound on the network.
**Why only you:** the remaining checks need your SonarQube token (never
committed; agents don't read `.env`, CLAUDE.md §8) and your physical iPhone.

1. Phone: install with `scripts/run-on-iphone.sh`; add the SonarQube server at
   `http://192.168.1.53:9000` with your token.
2. Phone: make SonarQube return a 401 (bad token), then confirm the app keeps
   the backend session and the Jenkins/GitHub clients — no global logout. In
   the other direction, sign out of the backend and confirm the SonarQube
   client keeps working with its own credentials.
3. Phone: walk the SQ-CRED/PROJ/QUALITY screens (projects, measures, issues,
   gate, file source) against the lab server. `api/measures/search`,
   `api/sources/show` and `api/rules/show` response shapes are only
   documented, not verified — this pass is the check.

**Evidence:** note + screenshots of the auth-isolation behaviour.
