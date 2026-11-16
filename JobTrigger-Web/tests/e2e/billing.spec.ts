import { expect, test } from "@playwright/test";

import { signUp } from "./flows";
import { uniqueEmail } from "./session";

// Paddle.js is stubbed so the specs prove how the page loads and uses it
// (the nonce'd script is allowed by the billing page's CSP, the checkout is
// opened with the transaction the backend created) without reaching Paddle.
const paddleStub = `
  window.__paddle = { opened: [] };
  window.Paddle = {
    Environment: { set(env) { window.__paddle.env = env; } },
    Initialize(options) { window.__paddle.token = options.token; },
    Checkout: { open(options) { window.__paddle.opened.push(options.transactionId); } },
  };
`;

test("the billing page loads Paddle.js under its own CSP and opens the checkout", async ({
  page,
}) => {
  await page.route("https://cdn.paddle.com/paddle/v2/paddle.js", (route) =>
    route.fulfill({ contentType: "text/javascript", body: paddleStub }),
  );
  const violations: string[] = [];
  page.on("console", (message) => {
    if (/Content Security Policy/i.test(message.text())) violations.push(message.text());
  });

  await signUp(page, uniqueEmail("free-plan"));
  const response = await page.goto("/account/billing");
  const csp = response!.headers()["content-security-policy"];
  expect(csp).toContain("script-src 'self'");
  expect(csp).toContain("https://cdn.paddle.com");
  expect(csp).toContain("connect-src 'self' https://sandbox-checkout-service.paddle.com");
  expect(csp).toContain("frame-src https://sandbox-buy.paddle.com");
  expect(csp).not.toContain("unsafe-inline");
  // Sandbox only: the production hosts are not trusted by a sandbox page.
  expect(csp).not.toContain("https://buy.paddle.com");

  const yearly = page.getByRole("button", { name: "Upgrade, yearly" });
  await expect(yearly).toBeEnabled();
  await yearly.click();
  await expect
    .poll(() =>
      page.evaluate(
        () => (window as unknown as { __paddle: { opened: string[] } }).__paddle.opened,
      ),
    )
    .toEqual(["txn_e2e_fake"]);
  expect(
    await page.evaluate(
      () => (window as unknown as { __paddle: { token: string } }).__paddle.token,
    ),
  ).toBe("test_e2efaketoken0123456789");
  expect(violations).toEqual([]);
});

test("every other page keeps the strict CSP: Paddle is allowed on the billing page only", async ({
  page,
}) => {
  await signUp(page, uniqueEmail("free-plan"));
  for (const path of ["/account", "/servers", "/", "/pricing", "/sign-in"]) {
    const response = await page.goto(path);
    const csp = response!.headers()["content-security-policy"];
    expect(csp, path).not.toContain("paddle.com");
    expect(csp, path).not.toContain("frame-src");
  }
});

test("the account page links to billing", async ({ page }) => {
  await signUp(page, uniqueEmail("free-plan"));
  await page.goto("/account");
  await page.getByRole("link", { name: "Billing" }).click();
  await expect(page).toHaveURL(/\/account\/billing$/);
  await expect(page.getByRole("heading", { name: "Billing", level: 1 })).toBeVisible();
});

test("a Pro user from a store is told where to manage it and cannot buy again", async ({
  page,
}) => {
  await signUp(page, uniqueEmail("pro-plan"));
  await page.goto("/account/billing");

  await expect(page.getByText("managed by the store you bought it in")).toBeVisible();
  await expect(page.getByRole("button", { name: /Upgrade/ })).toHaveCount(0);
});

test("with billing off, the billing page says buying here isn't available", async ({ page }) => {
  await signUp(page);
  await page.goto("/account/billing");

  await expect(page.getByText("Buying on the website isn't available right now")).toBeVisible();
  await expect(page.getByRole("button", { name: /Upgrade/ })).toHaveCount(0);
});
