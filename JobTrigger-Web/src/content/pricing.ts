/*
 * The one pricing list (US-SUB-08, P20-33). The /pricing page renders
 * exactly this and nothing else, so the page can't drift from the plans.
 *
 * Source of truth for the numbers is the entitlements matrix in
 * docs/subscription/02-business-model.md §3 (which the backend's plans.js
 * and the app's Entitlements mirror); pricing.test.ts pins the values, so
 * changing a limit here is a deliberate two-place edit.
 *
 * Wording follows docs/market/competitive-analysis.md §7.2: no competitor
 * names, and nothing that needs a qualifier while features are pre-launch.
 */

import type { ReleaseView } from "./release";

export type PlanId = "free" | "pro";

export type Plan = {
  id: PlanId;
  name: string;
  tagline: string;
  /** What it costs, in words; the store shows the local price. */
  price: string;
  /** Under the price. */
  priceNote: string;
  highlights: readonly string[];
};

export const plans = [
  {
    id: "free",
    name: "Free",
    tagline: "One server, fully usable.",
    price: "$0",
    priceNote: "Free to start, no card needed.",
    highlights: [
      "One CI tool at a time",
      "One saved server or account",
      "Browse, search, trigger with parameters, live logs, history, stages and tests",
      "Face ID / fingerprint app lock",
    ],
  },
  {
    id: "pro",
    name: "Pro",
    tagline: "Your whole CI estate.",
    price: "$3.99 / month",
    priceNote:
      "Or $29.99 / year, with a 7-day free trial on the yearly plan. Prices are in USD; the App Store and Google Play show your local price.",
    highlights: [
      "Jenkins, GitHub Actions and SonarQube together",
      "As many servers and accounts as you need",
      "Notifications when a build finishes, even with the app closed",
      "Home-screen widget and unlimited pinned jobs",
      "Build trends, nodes, queue and views",
    ],
  },
] as const satisfies readonly Plan[];

export type Cell = { included: true; note?: string } | { included: false };

export type ComparisonRow = {
  label: string;
  free: Cell;
  pro: Cell;
};

const yes = (note?: string): Cell => (note ? { included: true, note } : { included: true });
const no: Cell = { included: false };

/** Free vs Pro, in the order the page shows them. */
export const comparison: readonly ComparisonRow[] = [
  { label: "Trigger, logs, history, stages and tests", free: yes(), pro: yes() },
  { label: "Saved servers and accounts", free: yes("1"), pro: yes("As many as you need") },
  { label: "CI tools at the same time", free: yes("One"), pro: yes("All of them") },
  { label: "Pinned jobs", free: yes("3"), pro: yes("Unlimited") },
  { label: "Build notifications with the app closed", free: no, pro: yes() },
  { label: "Home-screen widget", free: no, pro: yes() },
  { label: "Build trends, nodes, queue and views", free: no, pro: yes() },
  { label: "Set up servers on this website", free: yes(), pro: yes() },
  { label: "App lock, sign out everywhere, delete account", free: yes(), pro: yes() },
];

/** Said on the page under the table. */
export const pricingPromises = [
  "Security and account controls are never paid features.",
  "If you drop to Free, nothing you saved is deleted. One server stays usable and the rest wait for you.",
  "Pro is bought in the JobTrigger app, through the App Store or Google Play, and renews until you cancel it there.",
] as const;

/**
 * The plans, the comparison and the promises for [release] (release/tools.json).
 * The constants above are the wording once several tools are released; while
 * only one is (release 1.0, Jenkins), nothing may suggest tools "together" or
 * name tools the release doesn't ship, so those two lines change. With
 * several released tools this returns the constants unchanged.
 */
export function pricingFor(release: ReleaseView): {
  plans: readonly Plan[];
  comparison: readonly ComparisonRow[];
  promises: readonly string[];
} {
  if (release.released.length > 1) return { plans, comparison, promises: pricingPromises };
  return {
    plans: plans.map((plan) =>
      plan.id === "pro"
        ? {
            ...plan,
            highlights: plan.highlights.map((line) =>
              line === "Jenkins, GitHub Actions and SonarQube together"
                ? "More tools together as they release"
                : line,
            ),
          }
        : plan,
    ),
    comparison: comparison.map((row) =>
      row.label === "CI tools at the same time"
        ? { ...row, pro: yes("Jenkins today; more as they release") }
        : row,
    ),
    promises: pricingPromises,
  };
}
