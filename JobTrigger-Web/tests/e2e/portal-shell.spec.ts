import { expect, test } from "@playwright/test";

import { signUp } from "./flows";

test("a signed-out visit to the portal goes to sign-in and comes back after", async ({ page }) => {
  await page.goto("/servers");

  await expect(page).toHaveURL(/\/sign-in\?next=%2Fservers$/);
});

test("the sidebar shows the account and marks the current page", async ({ page }) => {
  const email = await signUp(page);
  await page.goto("/servers");

  const nav = page.getByRole("navigation", { name: "Portal" });
  await expect(nav.getByRole("link", { name: "My servers" })).toHaveAttribute(
    "aria-current",
    "page",
  );
  await expect(nav.getByRole("link", { name: "Add server" })).not.toHaveAttribute("aria-current");
  await expect(page.getByText(email)).toBeVisible();
  // The card is hidden on phones (compact sidebar); its copy follows app-stores.
  await expect(page.getByText(/will be waiting in the JobTrigger app/)).toBeAttached();
});

test("sign out clears the session and returns home", async ({ page, context }) => {
  await signUp(page);
  await page.goto("/servers");

  await page.getByRole("button", { name: "Sign out" }).click();
  await page.waitForURL((url) => url.pathname === "/");

  expect((await context.cookies()).find((cookie) => cookie.name === "jt_session")).toBeUndefined();
  await page.goto("/servers");
  await expect(page).toHaveURL(/\/sign-in/);
});
