/*
 * The one feature-status list (US-WEB-22, WEB-B7). Every badge, disabled
 * action, comparison cell and "coming soon" sentence on the site reads its
 * status from here — no page hard-codes it.
 *
 * Keeping it true:
 * - Seeded from the "Feature availability" table in
 *   docs/user-stories/web/17-website.md (as of 2026-10-24).
 * - A feature becomes `live` only when its stories are done in
 *   tasks/README.md. The PR that ships it in the app (or the release that
 *   puts it in the stores) flips it here, in the same change or a linked
 *   follow-up.
 * - feature-status.test.ts pins every status, so a flip is always a
 *   deliberate two-line change.
 */

export type FeatureStatus = "live" | "beta" | "soon" | "planned";

type Feature = {
  label: string;
  status: FeatureStatus;
  /** Why it has this status — the task-tracker evidence. */
  source: string;
};

export const features = {
  "jenkins-core": {
    label: "Jenkins: browse, trigger, logs, history, stages, tests",
    status: "live",
    source: "Phases 4, 5, 7 done",
  },
  "jenkins-extended": {
    label: "Jenkins: notifications, pinned jobs, widget, nodes, queue, app lock",
    status: "live",
    source: "Phase 11 done",
  },
  "app-stores": {
    label: "App on the App Store and Google Play",
    status: "soon",
    source: "release-checklist.md pending; app at 1.0.0+1",
  },
  "github-accounts": {
    label: "GitHub: accounts, repositories, workflows",
    status: "live",
    source: "P8 GH-CRED + GH-REPO done",
  },
  "github-runs": {
    // The epic lists runs/logs as not shipped but shows GitHub as Beta:
    // the badge is what visitors see (owner decision 2026-10-26).
    label: "GitHub: runs, logs, history",
    status: "beta",
    source: "P8 in progress (11 of 28)",
  },
  "sonarqube-save": {
    label: "SonarQube: save a server",
    status: "live",
    source: "P10 SQ-CRED done",
  },
  "sonarqube-insights": {
    label: "SonarQube: projects, quality gates, measures, issues",
    status: "soon",
    source: "P10 in progress (6 of 16)",
  },
  "web-portal": {
    label: "Website: sign in, add/edit/delete servers, set active, account",
    status: "live",
    source: "Backend endpoints exist",
  },
  "web-test-connection": {
    label: "Website: test connection",
    status: "soon",
    source: "US-WEB-19 needs a new backend endpoint (backend track)",
  },
  "password-reset": {
    label: "Password reset",
    status: "soon",
    source: "Deferred, US-AUTH-08 in tasks/backlog.md",
  },
  "gitlab-ci": {
    label: "GitLab CI",
    status: "planned",
    source: "Docs-only epic GL",
  },
  circleci: {
    label: "CircleCI",
    status: "planned",
    source: "Docs-only epic CC",
  },
  "changelog-entries": {
    label: "Changelog entries",
    status: "soon",
    source: "No public release yet",
  },
} as const satisfies Record<string, Feature>;

export type FeatureId = keyof typeof features;

export function statusOf(id: FeatureId): FeatureStatus {
  return features[id].status;
}

/**
 * Whether the feature's actions can be used. `beta` can: it's badged but
 * works. `soon` and `planned` render disabled (US-WEB-22).
 */
export function isActionable(id: FeatureId): boolean {
  const status = statusOf(id);
  return status === "live" || status === "beta";
}

/** Badge copy; `live` features show no badge. */
export const statusLabels: Record<Exclude<FeatureStatus, "live">, string> = {
  beta: "Beta",
  soon: "Coming soon",
  planned: "Planned",
};
