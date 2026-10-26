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
  /**
   * Plain-language changelog lines (US-WEB-08). The upcoming entries are
   * built from these: `live` → Ships, `beta` → Beta, `soon` → Next.
   */
  changelog?: readonly string[];
};

export const features = {
  "jenkins-core": {
    label: "Jenkins: browse, trigger, logs, history, stages, tests",
    status: "live",
    source: "Phases 4, 5, 7 done",
    changelog: [
      "Jenkins: browse jobs, trigger with any parameter, live logs, stages, tests and history",
    ],
  },
  "jenkins-extended": {
    label: "Jenkins: notifications, pinned jobs, widget, nodes, queue, app lock",
    status: "live",
    source: "Phase 11 done",
    changelog: [
      "Build notifications, pinned jobs and the home-screen widget",
      "Nodes, queue, views and multibranch; Face ID / fingerprint app lock",
    ],
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
  "github-actions": {
    // The tool as a whole: what its badges show. Usable today (accounts,
    // repos, workflows) but not complete, hence beta (P15-08: split out of
    // github-runs so runs/logs aren't presented as usable).
    label: "GitHub Actions (the tool)",
    status: "beta",
    source: "P8 GH-CRED + GH-REPO done; runs pending",
    changelog: ["GitHub Actions: accounts, repositories and workflows"],
  },
  "github-runs": {
    label: "GitHub: runs, logs, history",
    status: "soon",
    source: "P8 in progress (11 of 28)",
    changelog: ["GitHub Actions runs, logs and history"],
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
    changelog: ["SonarQube projects, quality gates, measures and issues"],
  },
  "web-portal": {
    label: "Website: sign in, add/edit/delete servers, set active, account",
    status: "live",
    source: "Backend endpoints exist",
    changelog: ["Set up servers from your laptop on this website"],
  },
  "web-test-connection": {
    label: "Website: test connection",
    status: "soon",
    source: "US-WEB-19 needs a new backend endpoint (backend track)",
    changelog: ["Test connection from the website"],
  },
  "password-reset": {
    label: "Password reset",
    status: "soon",
    source: "Deferred, US-AUTH-08 in tasks/backlog.md",
    changelog: ["Password reset by email"],
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
