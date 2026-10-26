import { expect, test } from "@playwright/test";

import { PASSWORD, signUp } from "./flows";

const login = (email: string, password: string) =>
  fetch("http://127.0.0.1:5999/api/auth/login", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email, password }),
  }).then((response) => response.status);

test("change password re-checks the current one, then signs other devices out", async ({
  page,
}) => {
  const email = await signUp(page);
  await page.goto("/account");

  await page.getByLabel("Current password").fill("not-my-password");
  await page.getByLabel("New password", { exact: true }).fill("a-brand-new-password");
  await page.getByLabel("Confirm new password").fill("a-brand-new-password");
  await page.getByRole("button", { name: "Update password" }).click();
  const passwordCard = page.locator('section[aria-labelledby="password-heading"]');
  await expect(passwordCard.getByRole("alert")).toHaveText("Current password is incorrect");

  await page.getByLabel("Current password").fill(PASSWORD);
  await page.getByRole("button", { name: "Update password" }).click();
  await expect(page.getByText("Password changed. Other devices were signed out.")).toBeVisible();

  // Still signed in here (fresh pair), and only the new password works.
  await page.goto("/servers");
  await expect(page).toHaveURL(/\/servers$/);
  expect(await login(email, PASSWORD)).toBe(400);
  expect(await login(email, "a-brand-new-password")).toBe(200);
});

test("sign out everywhere confirms first, then ends this session too", async ({
  page,
  context,
}) => {
  await signUp(page);
  await page.goto("/account");

  await page.getByRole("button", { name: "Sign out all devices" }).click();
  const dialog = page.getByRole("dialog", { name: "Sign out of all devices?" });
  await expect(dialog.getByRole("button", { name: "Cancel" })).toBeFocused();
  await dialog.getByRole("button", { name: "Sign out everywhere" }).click();

  await expect(page).toHaveURL(/\/sign-in\?notice=signedOutEverywhere/);
  await expect(page.getByRole("status")).toHaveText("You're signed out on every device.");
  expect((await context.cookies()).find((cookie) => cookie.name === "jt_session")).toBeUndefined();
});

test("delete account needs the email typed and the password", async ({ page }) => {
  const email = await signUp(page);
  await page.goto("/account");

  const remove = page.getByRole("button", { name: "Delete my account" });
  await expect(remove).toHaveAttribute("aria-disabled", "true");
  await page.getByLabel("Type your email to confirm").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(PASSWORD);
  await expect(remove).not.toHaveAttribute("aria-disabled");
  await remove.click();

  await expect(page).toHaveURL(/\/sign-in\?notice=accountDeleted/);
  await expect(page.getByRole("status")).toHaveText(
    "Your account and every saved server were deleted.",
  );
  expect(await login(email, PASSWORD)).toBe(400);
});
