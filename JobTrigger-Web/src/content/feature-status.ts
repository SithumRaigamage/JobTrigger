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

import type { Tool } from "@/domain/credentials";

import { isToolReleased, toolVersion } from "./release";

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
    // The tool as a whole: accounts, repositories, workflows, runs, logs
    // and dispatch all ship in 1.0 (P8, P15-08, P22–P23), so it is live.
    label: "GitHub Actions (the tool)",
    status: "live",
    source: "Phases 8, 15, 22–23 done; runs, logs and dispatch ship in 1.0",
    changelog: ["GitHub Actions: accounts, repositories, workflows, runs, logs and dispatch"],
  },
  "github-runs": {
    label: "GitHub: runs, logs, history",
    status: "live",
    source: "Phases 22–23 done (runs, logs, history, dispatch)",
    changelog: ["GitHub Actions runs, logs and history"],
  },
  "sonarqube-save": {
    label: "SonarQube: save a server",
    status: "live",
    source: "P10 SQ-CRED done",
  },
  "sonarqube-insights": {
    label: "SonarQube: projects, quality gates, measures, issues",
    status: "live",
    source: "Phase 10 done (SQ-01…SQ-16), ships in 1.0",
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
    // Built 2026-11-12 (backend P20-73, app and web P20-74). Stays "soon"
    // until the backend is deployed with a real mail provider.
    source: "US-AUTH-08 built in Phase 20; waits for the backend deployment",
    changelog: ["Password reset by email"],
  },
  subscriptions: {
    label: "JobTrigger Pro (subscriptions)",
    status: "live",
    // Release 1.0.0 ships with billing enabled: the paywall and the website
    // Pro checkout are on sale once the store products and RevenueCat/Paddle
    // keys are configured. The Pro CTA is actionable in this release.
    source:
      "Phase 20 built; billing enabled in 1.0.0 with the store listings and backend deployment",
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
  // A tool this release doesn't ship has nothing to act on, whatever its
  // build status is.
  if (comingInVersion(id) !== null) return false;
  const status = statusOf(id);
  return status === "live" || status === "beta";
}

/** The tool each tool feature belongs to; other features belong to none. */
const featureTool: Partial<Record<FeatureId, Tool>> = {
  "github-accounts": "github",
  "github-actions": "github",
  "github-runs": "github",
  "sonarqube-save": "sonarqube",
  "sonarqube-insights": "sonarqube",
};

/**
 * The release a feature arrives in, when its tool isn't in this release yet
 * (release/tools.json); null otherwise. Badges and labels show it as
 * "Coming in 1.2" instead of the build status.
 */
export function comingInVersion(id: FeatureId): string | null {
  const tool = featureTool[id];
  if (!tool || isToolReleased(tool)) return null;
  return toolVersion(tool) ?? null;
}

/** Badge copy; `live` features show no badge. */
export const statusLabels: Record<Exclude<FeatureStatus, "live">, string> = {
  beta: "Beta",
  soon: "Coming soon",
  planned: "Planned",
};
