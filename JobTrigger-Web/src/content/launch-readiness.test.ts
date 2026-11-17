import { describe, expect, it } from "vitest";

import { statusOf } from "./feature-status";
import { detail, missingDetails, siteDetails } from "./site-details";

describe("site details", () => {
  it("render as their bracketed placeholder while unset", () => {
    if (siteDetails.securityEmail === null) {
      expect(detail("securityEmail")).toBe("[SECURITY EMAIL]");
    }
  });

  // Guard: the site launches with the app. By then every placeholder in the
  // legal and security pages must be real (UI-UX/Web/README.md list).
  it("are all filled in once the app is live", () => {
    if (statusOf("app-stores") !== "live") return;

    expect(missingDetails()).toEqual([]);
  });
});
