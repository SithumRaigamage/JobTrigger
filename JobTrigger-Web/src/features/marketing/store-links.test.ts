import { describe, expect, it } from "vitest";

import { statusOf } from "@/content/feature-status";

import { storeLinks } from "./site-links";

// Guard (P15-06d): the site must never announce the apps as available
// while a store button would have nowhere to go.
describe("store links", () => {
  it("are set whenever the app is marked live", () => {
    if (statusOf("app-stores") !== "live") return;

    expect(storeLinks.appStore, "storeLinks.appStore").toMatch(/^https:\/\/apps\.apple\.com\//);
    expect(storeLinks.googlePlay, "storeLinks.googlePlay").toMatch(
      /^https:\/\/play\.google\.com\//,
    );
  });
});
