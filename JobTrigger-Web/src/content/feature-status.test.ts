import { describe, expect, it } from "vitest";

import { features, isActionable, statusOf, type FeatureId } from "./feature-status";

describe("feature status list", () => {
  // Pinned on purpose: flipping a status means editing this expectation in
  // the same change, with its tasks/README.md evidence (US-WEB-22).
  it("matches the agreed statuses", () => {
    const statuses = Object.fromEntries(
      Object.entries(features).map(([id, feature]) => [id, feature.status]),
    );

    expect(statuses).toEqual({
      "jenkins-core": "live",
      "jenkins-extended": "live",
      "app-stores": "soon",
      "github-accounts": "live",
      "github-runs": "beta",
      "sonarqube-save": "live",
      "sonarqube-insights": "soon",
      "web-portal": "live",
      "web-test-connection": "soon",
      "password-reset": "soon",
      "gitlab-ci": "planned",
      circleci: "planned",
      "changelog-entries": "soon",
    });
  });

  it("gives every feature a label and its evidence", () => {
    for (const feature of Object.values(features)) {
      expect(feature.label).not.toBe("");
      expect(feature.source).not.toBe("");
    }
  });
});

describe("isActionable", () => {
  it.each<[FeatureId, boolean]>([
    ["jenkins-core", true],
    ["github-runs", true],
    ["web-test-connection", false],
    ["gitlab-ci", false],
  ])("%s → %s", (id, expected) => {
    expect(isActionable(id)).toBe(expected);
    expect(statusOf(id)).toBe(features[id].status);
  });
});
