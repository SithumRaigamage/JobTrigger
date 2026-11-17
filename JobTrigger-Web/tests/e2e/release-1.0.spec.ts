import { expect, test } from "@playwright/test";

import { signUp } from "./flows";

// A small smoke run against the REAL release manifest (release 1.0, all three
// built tools), served by its own build (playwright.config.ts: the "release-1.0"
// project and second web server). Every other spec runs against an all-tools
// manifest so hidden tools stay tested; this one proves what actually ships.

// Counted per account: the other specs run in parallel against the same backend.
const toolRequestsBy = async (email: string) =>
  (
    (await (
      await fetch(`http://127.0.0.1:5999/__stats?email=${encodeURIComponent(email)}`)
    ).json()) as { toolRequests: number }
  ).toolRequests;

test("release 1.0: the public pages lead with all three tools", async ({ page }) => {
  await page.goto("/");
  await expect(
    page.getByText(
      "JobTrigger puts Jenkins, GitHub Actions and SonarQube in your pocket. Trigger jobs, watch logs stream live, and know the moment a build breaks.",
    ),
  ).toBeVisible();
  const strip = page.getByLabel("Supported tools");
  for (const name of ["Jenkins", "GitHub Actions", "SonarQube"]) {
    await expect(strip).toContainText(name);
  }

  const integrations = await page.goto("/integrations");
  expect(integrations!.ok()).toBe(true);
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  for (const name of ["Jenkins", "GitHub Actions", "SonarQube"]) {
    await expect(page.getByText(name, { exact: true }).first()).toBeVisible();
  }
  await expect(page.getByText(/Coming in 1\.[12]/)).toHaveCount(0);
  await expect(page.locator('meta[name="description"]')).toHaveAttribute(
    "content",
    "Jenkins, GitHub Actions and SonarQube in JobTrigger: what works today, and what's coming.",
  );

  await page.goto("/features");
  const github = page.locator("section", {
    has: page.getByRole("heading", { name: "Jenkins and GitHub, side by side." }),
  });
  await expect(github).toContainText("GitHub Actions");
  await expect(github).not.toContainText("Coming in 1.2");
  await expect(page.getByRole("main")).not.toContainText(/Coming in 1\.[12]/);

  await page.goto("/pricing");
  await expect(page.getByRole("heading", { level: 1 })).toContainText("Free to start");
  await expect(page.getByRole("main")).toContainText(
    "Jenkins, GitHub Actions and SonarQube together",
  );
});

test("release 1.0: the add-server picker offers all three tools and never asks for an unreleased one", async ({
  page,
}) => {
  const urls: string[] = [];
  page.on("request", (request) => urls.push(request.url()));
  const email = await signUp(page);
  await expect(page).toHaveURL(/\/servers\/new$/);

  const picker = page.getByRole("navigation", { name: "Tool" });
  await expect(picker.getByRole("link")).toHaveCount(3);
  for (const name of ["Jenkins", "GitHub", "SonarQube"]) {
    await expect(picker.getByRole("link", { name: new RegExp(name) })).toBeVisible();
  }

  const next = page.getByRole("region", { name: "Coming next" });
  await expect(next.getByRole("listitem")).toHaveCount(2);
  for (const [name, version] of [
    ["GitLab CI", "1.3"],
    ["CircleCI", "1.3"],
  ]) {
    const item = next.getByRole("listitem").filter({ hasText: name! });
    await expect(item).toContainText(version!);
    await expect(item.getByRole("link")).toHaveCount(0);
  }

  // A released tool is a real choice now.
  await page.goto("/servers/new?tool=github");
  await expect(picker.getByRole("link", { name: /GitHub/ })).toHaveAttribute(
    "aria-current",
    "page",
  );
  await expect(page.getByRole("heading", { name: /GitHub/ }).first()).toBeVisible();

  // A link to a tool no release ships yet lands on Jenkins.
  await page.goto("/servers/new?tool=gitlab");
  await expect(picker.getByRole("link", { name: /Jenkins/ })).toHaveAttribute(
    "aria-current",
    "page",
  );
  await expect(page.getByRole("heading", { name: /Jenkins/ }).first()).toBeVisible();

  // The browser never asked for an unreleased tool's credentials, and the
  // account made no credential requests during this run.
  expect(urls.filter((url) => /gitlab-credentials|circleci-credentials/.test(url))).toEqual([]);
  expect(await toolRequestsBy(email)).toBe(0);
});
