import { expect, test } from "@playwright/test";

import { signUp } from "./flows";

const TOKEN = "fake-jenkins-token-a91f";

test("add a Jenkins server, see it saved, and find it masked in the list", async ({ page }) => {
  await signUp(page);
  await page.goto("/servers/new");

  await page.getByLabel("Name", { exact: true }).fill("Acme production");
  await page.getByLabel("Server URL").fill(" https://ci.acme.dev/ ");
  await page.getByLabel("Username").fill("sam");
  await page.getByLabel("API token", { exact: true }).fill(TOKEN);
  await expect(page.getByLabel("API token", { exact: true })).toHaveAttribute(
    "autocomplete",
    "off",
  );
  await page.getByRole("button", { name: "Save server" }).click();

  await page.waitForURL(/\/servers\/saved\?tool=jenkins&id=/);
  await expect(page.getByText("✓ Saved · Acme production")).toBeVisible();
  await expect(page.getByRole("heading", { level: 1 })).toHaveText(
    /Saved\. It.ll be\s*waiting for you\./,
  );

  const list = await page.goto("/servers");
  await expect(page.getByText("https://ci.acme.dev · sam")).toBeVisible();
  await expect(page.getByText("••••a91f")).toBeVisible();
  expect(await list!.text()).not.toContain(TOKEN);
});

test("the tool picker switches the form, keeping the app's labels", async ({ page }) => {
  await signUp(page);
  await page.goto("/servers/new");
  await page
    .getByRole("navigation", { name: "Tool" })
    .getByRole("link", { name: /SonarQube/ })
    .click();

  await expect(page).toHaveURL(/tool=sonarqube/);
  await expect(page.getByLabel("Instance URL")).toHaveValue("https://sonarcloud.io");
  await expect(page.getByLabel("User token")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Getting a SonarQube token" })).toBeVisible();
});

test("validation and the http:// warning follow the app's rules", async ({ page }) => {
  await signUp(page);
  await page.goto("/servers/new?tool=jenkins");

  await page.getByLabel("Server URL").fill("http://jenkins.lan:8080");
  await expect(
    page.getByText(/Not encrypted: your username and password or token are sent/),
  ).toBeVisible();
  await page.getByLabel("Server URL").fill("jenkins.lan");
  await page.getByRole("button", { name: "Save server" }).click();

  await expect(page.getByText("The URL must start with https:// (or http://).")).toBeVisible();
  await expect(page.getByText("Enter a name for this server.")).toBeVisible();
  // What was typed survives the failed save.
  await expect(page.getByLabel("Server URL")).toHaveValue("jenkins.lan");
});

test("Test connection is shown disabled while it's coming soon", async ({ page }) => {
  await signUp(page);
  await page.goto("/servers/new");

  const test = page.getByRole("button", { name: "Test connection Coming soon" });
  await expect(test).toHaveAttribute("aria-disabled", "true");
  await expect(test).toHaveAccessibleDescription(
    "You can test the connection from the app after saving.",
  );
});
