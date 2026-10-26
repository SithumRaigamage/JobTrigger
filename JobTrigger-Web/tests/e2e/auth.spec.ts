import { expect, test } from "@playwright/test";

import { PASSWORD, signUp } from "./flows";
import { fakeToken, sealedSession, uniqueEmail } from "./session";

test("sign up creates the account and an HttpOnly, SameSite=Lax session", async ({
  page,
  context,
}) => {
  await signUp(page, uniqueEmail());

  const session = (await context.cookies()).find((cookie) => cookie.name === "jt_session");
  expect(session).toMatchObject({ httpOnly: true, sameSite: "Lax", secure: true });
  // The page never carries a JobTrigger token.
  expect(await page.content()).not.toMatch(/fake\.[A-Za-z0-9_-]+\.sig/);
});

test("sign up checks the password as the app does", async ({ page }) => {
  await page.goto("/sign-up");
  await page.getByLabel("Password", { exact: true }).fill("short");
  await page.getByLabel("Confirm password").fill("shorter");

  await expect(page.getByText("Passwords don't match.")).toBeVisible();
  await page.getByLabel("Email").fill("not-an-email");
  await page.getByRole("button", { name: "Create account" }).click();
  await expect(page.getByText("Enter a valid email address")).toBeVisible();
  await expect(page.getByText("Password must be at least 8 characters long")).toBeVisible();
});

test("signing in sends you to your servers; a signed-in visit to sign-in skips it", async ({
  page,
  context,
}) => {
  const email = uniqueEmail();
  await signUp(page, email);
  await context.clearCookies();

  await page.goto("/sign-in");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(PASSWORD);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL("**/servers");

  await page.goto("/sign-in");
  await expect(page).toHaveURL(/\/servers$/);
});

test("a wrong password shows the backend's message and keeps the email", async ({ page }) => {
  const email = uniqueEmail();
  await signUp(page, email);
  await page.context().clearCookies();

  await page.goto("/sign-in");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password", { exact: true }).fill("wrong-password");
  await page.getByRole("button", { name: "Sign in" }).click();

  await expect(page.locator("form").getByRole("alert")).toHaveText("Invalid credentials");
  await expect(page.getByLabel("Email")).toHaveValue(email);
  await expect(page.getByLabel("Password", { exact: true })).toHaveValue("");
});

test("the login limiter reads as the app's rate-limit copy", async ({ page }) => {
  await page.goto("/sign-in");
  await page.getByLabel("Email").fill(uniqueEmail("ratelimited"));
  await page.getByLabel("Password", { exact: true }).fill(PASSWORD);
  await page.getByRole("button", { name: "Sign in" }).click();

  await expect(page.locator("form").getByRole("alert")).toHaveText(
    "Too many attempts. Please wait a few minutes and try again.",
  );
});

test("after 30 idle minutes a portal visit goes to sign-in with a notice", async ({
  page,
  context,
  baseURL,
}) => {
  await context.addCookies([
    {
      name: "jt_session",
      value: await sealedSession({
        accessToken: fakeToken("access", 600),
        refreshToken: fakeToken("refresh", 86_400),
        email: "sam@acme.dev",
        lastActivity: Date.now() - 31 * 60_000,
      }),
      url: baseURL!,
    },
  ]);

  await page.goto("/servers");

  await expect(page).toHaveURL(/\/sign-in\?notice=idle&next=%2Fservers$/);
  await expect(page.getByRole("status")).toHaveText(
    "You were signed out after 30 minutes without activity.",
  );
  expect((await context.cookies()).find((cookie) => cookie.name === "jt_session")).toBeUndefined();
});
