import { expect, test } from "@playwright/test";

import { backendToken, seed } from "./backend";
import { PASSWORD, signUp } from "./flows";

const JENKINS_TOKEN = "fake-jenkins-token-a91f";
const GITHUB_TOKEN = "github_pat_11ABCDEFG0123456789_secretQ7rM";

test("a new account sees the empty state and an Add link per tool", async ({ page }) => {
  await signUp(page);
  await page.goto("/servers");

  await expect(page.getByRole("heading", { name: "No servers yet" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Add SonarQube →" })).toHaveAttribute(
    "href",
    "/servers/new?tool=sonarqube",
  );
});

test("saved servers are listed with masked tokens only", async ({ page }) => {
  const email = await signUp(page);
  const token = await backendToken(email, PASSWORD);
  await seed(token, "/api/credentials", {
    serverName: "Acme production",
    jenkinsURL: "https://ci.acme.dev",
    username: "sam",
    password: JENKINS_TOKEN,
    isDefault: true,
  });
  await seed(token, "/api/github-credentials", {
    label: "Acme org",
    token: GITHUB_TOKEN,
    defaultOwner: "sam-acme",
  });

  const response = await page.goto("/servers");

  const table = page.getByRole("region", { name: "Servers" });
  await expect(table.getByRole("rowheader", { name: /Acme production/ })).toBeVisible();
  await expect(table.getByText("••••a91f")).toBeVisible();
  await expect(table.getByText("••••Q7rM")).toBeVisible();
  await expect(table.getByText("@sam-acme")).toBeVisible();
  await expect(table.getByText("✓ Active")).toHaveCount(1);
  await expect(page.getByRole("listitem").filter({ hasText: "Jenkins server" })).toHaveText(
    /1\s*Jenkins server/,
  );

  // WEB-B4: the table scrolls inside its box; the page itself never does.
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);

  // US-WEB-11: the full value never reaches the browser — not in the HTML
  // nor in the RSC payload embedded in it.
  const html = await response!.text();
  expect(html).not.toContain(JENKINS_TOKEN);
  expect(html).not.toContain(GITHUB_TOKEN);
});

test("Make active moves the tool's default (US-WEB-18)", async ({ page }) => {
  const email = await signUp(page);
  const token = await backendToken(email, PASSWORD);
  const server = (name: string, isDefault: boolean) => ({
    serverName: name,
    jenkinsURL: `https://${name.toLowerCase().replace(" ", "-")}.example`,
    username: "sam",
    password: JENKINS_TOKEN,
    isDefault,
  });
  await seed(token, "/api/credentials", server("Acme production", true));
  await seed(token, "/api/credentials", server("Home lab", false));

  await page.goto("/servers");
  await page.getByRole("button", { name: "Make active Home lab" }).click();

  const row = (name: string) => page.getByRole("row").filter({ hasText: name });
  await expect(row("Home lab").getByText("✓ Active")).toBeVisible();
  await expect(row("Acme production").getByRole("button", { name: /Make active/ })).toBeVisible();
});
