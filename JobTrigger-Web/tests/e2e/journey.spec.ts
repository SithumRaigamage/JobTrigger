import { expect, test } from "@playwright/test";

import { PASSWORD } from "./flows";
import { uniqueEmail } from "./session";

// The portal's reason to exist (epic WEB): from the home page to a server
// waiting for the phone, using only the site's own links and forms.
test("home → sign up → add a server → saved → in my servers", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "Set up your servers" }).first().click();
  await expect(page).toHaveURL(/\/sign-in$/);
  await page.getByRole("link", { name: "Create an account →" }).click();

  await page.getByLabel("Email").fill(uniqueEmail("journey"));
  await page.getByLabel("Password", { exact: true }).fill(PASSWORD);
  await page.getByLabel("Confirm password").fill(PASSWORD);
  await page.getByRole("button", { name: "Create account" }).click();

  await expect(page.getByRole("heading", { level: 1 })).toHaveText("Add a server");
  await page
    .getByRole("navigation", { name: "Tool" })
    .getByRole("link", { name: /GitHub/ })
    .click();
  await page.getByLabel("Label").fill("Acme org");
  await page.getByLabel("Personal access token").fill("github_pat_11ABCDEFG0123456789_secretQ7rM");
  await page.getByRole("button", { name: "Save server" }).click();

  await expect(page.getByText("✓ Saved · Acme org")).toBeVisible();
  await page.getByRole("link", { name: "Back to my servers" }).click();
  await expect(page.getByRole("rowheader", { name: /Acme org/ })).toBeVisible();
  await expect(page.getByText("••••Q7rM")).toBeVisible();
});
