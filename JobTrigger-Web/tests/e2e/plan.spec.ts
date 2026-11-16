import { expect, test } from "@playwright/test";

import { signUp } from "./flows";
import { uniqueEmail } from "./session";

test("the account page shows no plan while billing is off", async ({ page }) => {
  await signUp(page);
  await page.goto("/account");

  await expect(page.getByRole("heading", { name: "Account", level: 1 })).toBeVisible();
  await expect(page.getByRole("region", { name: "Plan" })).toHaveCount(0);
});

test("a Free user sees their limits and that Pro is bought in the app", async ({ page }) => {
  await signUp(page, uniqueEmail("free-plan"));
  await page.goto("/account");

  const plan = page.getByRole("region", { name: "Plan" });
  await expect(plan).toContainText("You're on the Free plan.");
  await expect(plan).toContainText("Pro is bought in the JobTrigger app.");
});

test("a Pro user sees where it was bought and how to manage it", async ({ page }) => {
  await signUp(page, uniqueEmail("pro-plan"));
  await page.goto("/account");

  const plan = page.getByRole("region", { name: "Plan" });
  await expect(plan).toContainText(
    "You're on Pro through the App Store. It renews on March 3, 2027.",
  );
  await expect(plan).toContainText("Settings");
  await expect(page.getByText(/does not cancel your App Store subscription/)).toBeVisible();
});

test("/pricing shows Coming soon, not a buy button, while billing is off", async ({ page }) => {
  await page.goto("/pricing");

  await expect(page.getByRole("heading", { level: 1 })).toContainText("Free to start");
  await expect(page.getByRole("button", { name: /Get Pro in the app/ })).toHaveAttribute(
    "aria-disabled",
    "true",
  );
  await expect(page.getByRole("link", { name: "Pricing" }).first()).toBeVisible();
});
