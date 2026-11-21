import { describe, expect, it } from "vitest";

import { afterLaunch, firstReleaseVersion, releases, upcomingRelease } from "./changelog";

describe("upcoming changelog entries", () => {
  it("ships every live feature, in list order", () => {
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
      {
        tag: "Ships",
        text: "GitHub Actions: accounts, repositories, workflows, runs, logs and dispatch",
      },
      { tag: "Ships", text: "GitHub Actions runs, logs and history" },
      { tag: "Ships", text: "SonarQube projects, quality gates, measures and issues" },
      { tag: "Ships", text: "Set up servers from your laptop on this website" },
    ]);
  });

  it("lists the remaining soon features as next, and never planned ones", () => {
    // US-WEB-19 is `planned` (option c), so it is no longer "next".
    expect(afterLaunch().map((item) => item.text)).toEqual(["Password reset by email"]);
    expect(afterLaunch().every((item) => item.tag === "Next")).toBe(true);
  });

  it("has one released v1.0 entry, with real dates", () => {
    expect(releases).toHaveLength(1);
    expect(releases[0].version).toBe(firstReleaseVersion);
    expect(releases[0].date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(releases[0].items.length).toBeGreaterThan(0);
  });
});
