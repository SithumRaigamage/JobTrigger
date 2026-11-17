import { comingInVersion, features, type FeatureId, type FeatureStatus } from "./feature-status";

/*
 * The changelog (US-WEB-08). Released versions are authored here, newest
 * first, in the same pull request as the release — no CMS. Until the first
 * public release, the page shows the upcoming one instead, built from the
 * feature statuses so it can't drift from the rest of the site.
 */

export type ChangeTag = "New" | "Improved" | "Fixed";

export type Release = {
  /** As shipped, e.g. "v1.0". */
  version: string;
  /** ISO date, e.g. "2026-12-01". */
  date: string;
  title: string;
  items: { tag: ChangeTag; text: string }[];
};

/** Shipped releases, newest first. */
export const releases: Release[] = [
  {
    version: "v1.0",
    date: "2026-11-17",
    title: "JobTrigger 1.0",
    items: [
      { tag: "New", text: "Jenkins, GitHub Actions and SonarQube in one app" },
      { tag: "New", text: "Trigger builds and workflows with every parameter they take" },
      { tag: "New", text: "Live logs, stages, tests and history for every run" },
      { tag: "New", text: "Notifications with per-watch rules — failures only, or back to green" },
      { tag: "New", text: "Pinned jobs, saved views, the build queue and nodes" },
      { tag: "New", text: "Set up servers from your laptop on this website" },
      {
        tag: "Improved",
        text: "Last-updated and offline banners, and status shown by shape and words",
      },
    ],
  },
];

/** The first release's version: the app's 1.0.0 (pubspec.yaml). */
export const firstReleaseVersion = "v1.0";

export type UpcomingTag = "Ships" | "Beta" | "Next";

const tagFor: Partial<Record<FeatureStatus, UpcomingTag>> = {
  live: "Ships",
  beta: "Beta",
  soon: "Next",
};

type Entry = [FeatureId, (typeof features)[FeatureId]];

const entries = (): Entry[] =>
  (Object.entries(features) as Entry[]).filter(([, feature]) => "changelog" in feature);

const textsOf = (feature: Entry[1]): readonly string[] =>
  "changelog" in feature ? feature.changelog : [];

/**
 * Changelog lines for features in the given statuses, in list order. A
 * feature of a tool this release doesn't ship (release/tools.json) is left
 * out here: it is listed by [afterLaunch] with the release it arrives in.
 */
function linesFor(statuses: FeatureStatus[]) {
  return statuses.flatMap((status) =>
    entries()
      .filter(([id, feature]) => feature.status === status && comingInVersion(id) === null)
      .flatMap(([, feature]) => textsOf(feature).map((text) => ({ tag: tagFor[status]!, text }))),
  );
}

/** What the next release brings: everything live, then beta. */
export function upcomingRelease() {
  return linesFor(["live", "beta"]);
}

/**
 * What follows it: everything still `soon`, then the live and beta features
 * of tools a later release ships, with that release. Planned work isn't listed.
 */
export function afterLaunch() {
  const later = entries()
    .filter(([id, feature]) => comingInVersion(id) !== null && feature.status !== "planned")
    .flatMap(([id, feature]) =>
      textsOf(feature).map((text) => ({
        tag: "Next" as const,
        text: `${text} (release ${comingInVersion(id)})`,
      })),
    );
  return [...linesFor(["soon"]), ...later];
}
