import type { Page } from "@playwright/test";

import { uniqueEmail } from "./session";

export const PASSWORD = "correct-horse-battery";

/** Creates a fresh account through the real sign-up form; returns its email. */
export async function signUp(page: Page, email = uniqueEmail()) {
  await page.goto("/sign-up");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(PASSWORD);
  await page.getByLabel("Confirm password").fill(PASSWORD);
  await page.getByRole("button", { name: "Create account" }).click();
  await page.waitForURL("**/servers/new");
  return email;
}
