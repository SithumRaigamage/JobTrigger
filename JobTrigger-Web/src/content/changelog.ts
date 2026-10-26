import { features, type FeatureStatus } from "./feature-status";

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

/** Shipped releases, newest first. Empty until v1.0 ships. */
export const releases: Release[] = [];

/** The first release's version: the app's 1.0.0 (pubspec.yaml). */
export const firstReleaseVersion = "v1.0";

export type UpcomingTag = "Ships" | "Beta" | "Next";

const tagFor: Partial<Record<FeatureStatus, UpcomingTag>> = {
  live: "Ships",
  beta: "Beta",
  soon: "Next",
};

/** Changelog lines for features in the given statuses, in list order. */
function linesFor(statuses: FeatureStatus[]) {
  return statuses.flatMap((status) =>
    Object.values(features)
      .filter((feature) => feature.status === status && "changelog" in feature)
      .flatMap((feature) =>
        ("changelog" in feature ? feature.changelog : []).map((text) => ({
          tag: tagFor[status]!,
          text,
        })),
      ),
  );
}

/** What the next release brings: everything live, then beta. */
export function upcomingRelease() {
  return linesFor(["live", "beta"]);
}

/** What follows it: everything still `soon`. Planned work isn't listed. */
export function afterLaunch() {
  return linesFor(["soon"]);
}
