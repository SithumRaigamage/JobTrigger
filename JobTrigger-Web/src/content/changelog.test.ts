import { describe, expect, it } from "vitest";

import { afterLaunch, firstReleaseVersion, releases, upcomingRelease } from "./changelog";

describe("upcoming changelog entries", () => {
  it("ship every live feature, then beta, in list order", () => {
    expect(upcomingRelease()).toEqual([
      {
        tag: "Ships",
        text: "Jenkins: browse jobs, trigger with any parameter, live logs, stages, tests and history",
      },
      { tag: "Ships", text: "Build notifications, pinned jobs and the home-screen widget" },
      {
        tag: "Ships",
        text: "Nodes, queue, views and multibranch; Face ID / fingerprint app lock",
      },
      { tag: "Ships", text: "Set up servers from your laptop on this website" },
      { tag: "Beta", text: "GitHub Actions: accounts, repositories and workflows" },
    ]);
  });

  it("list soon features as next, and never planned ones", () => {
    expect(afterLaunch().map((item) => item.text)).toEqual([
      "GitHub Actions runs, logs and history",
      "SonarQube projects, quality gates, measures and issues",
      "Test connection from the website",
      "Password reset by email",
    ]);
    expect(afterLaunch().every((item) => item.tag === "Next")).toBe(true);
  });

  it("has one released v1.0 entry, with real dates", () => {
    expect(releases).toHaveLength(1);
    expect(releases[0].version).toBe(firstReleaseVersion);
    expect(releases[0].date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(releases[0].items.length).toBeGreaterThan(0);
  });
});
