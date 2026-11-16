import { expect, test } from "@playwright/test";

import { signUp } from "./flows";

// A small smoke run against the REAL release manifest (release 1.0, Jenkins
// only), served by its own build (playwright.config.ts: the "release-1.0"
// project and second web server). Every other spec runs against an all-tools
// manifest so hidden tools stay tested; this one proves what actually ships.

// Counted per account: the other specs run in parallel against the same backend.
const toolRequestsBy = async (email: string) =>
  (
    (await (
      await fetch(`http://127.0.0.1:5999/__stats?email=${encodeURIComponent(email)}`)
    ).json()) as { toolRequests: number }
  ).toolRequests;

test("release 1.0: the public pages lead with Jenkins and name the rest as coming next", async ({
  page,
}) => {
  await page.goto("/");
  await expect(
    page.getByText(
      "JobTrigger puts Jenkins in your pocket. SonarQube and GitHub Actions coming next.",
    ),
  ).toBeVisible();
  const strip = page.getByLabel("Supported tools");
  await expect(strip).toContainText("Jenkins");
  await expect(strip).toContainText("Coming next");

  const integrations = await page.goto("/integrations");
  expect(integrations!.ok()).toBe(true);
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  await expect(page.getByText("Coming in 1.2").first()).toBeVisible();
  await expect(page.locator('meta[name="description"]')).toHaveAttribute(
    "content",
    "Jenkins in JobTrigger: what works today. SonarQube and GitHub Actions coming next.",
  );

  await page.goto("/features");
  const github = page.locator("section", {
    has: page.getByRole("heading", { name: "Jenkins and GitHub, side by side." }),
  });
  await expect(github.getByText("Coming in 1.2")).toBeVisible();
  await expect(github.getByText(/✓ Accounts/)).toHaveCount(0);

  await page.goto("/pricing");
  await expect(page.getByRole("heading", { level: 1 })).toContainText("Free to start");
  await expect(page.getByRole("main")).not.toContainText(/GitHub|SonarQube/);
});

test("release 1.0: the add-server picker offers Jenkins only and nothing asks for GitHub or SonarQube", async ({
  page,
}) => {
  const urls: string[] = [];
  page.on("request", (request) => urls.push(request.url()));
  const email = await signUp(page);
  await expect(page).toHaveURL(/\/servers\/new$/);

  const picker = page.getByRole("navigation", { name: "Tool" });
  await expect(picker.getByRole("link")).toHaveCount(1);
  await expect(picker.getByRole("link", { name: /Jenkins/ })).toBeVisible();

  const next = page.getByRole("region", { name: "Coming next" });
  for (const [name, version] of [
    ["SonarQube", "1.1"],
    ["GitHub Actions", "1.2"],
    ["GitLab CI", "1.3"],
    ["CircleCI", "1.3"],
  ]) {
    const item = next.getByRole("listitem").filter({ hasText: name! });
    await expect(item).toContainText(version!);
    await expect(item.getByRole("link")).toHaveCount(0);
  }

  // A link to an unreleased tool lands on Jenkins.
  await page.goto("/servers/new?tool=github");
  await expect(picker.getByRole("link", { name: /Jenkins/ })).toHaveAttribute(
    "aria-current",
    "page",
  );
  await expect(page.getByRole("heading", { name: /Jenkins/ }).first()).toBeVisible();

  // The browser never asked for GitHub or SonarQube credentials, and neither
  // did the site's server on its behalf.
  expect(urls.filter((url) => /github-credentials|sonarqube-credentials/.test(url))).toEqual([]);
  expect(await toolRequestsBy(email)).toBe(0);
});
