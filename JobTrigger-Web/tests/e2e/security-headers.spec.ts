import { expect, test } from "@playwright/test";

import { publicPages } from "./pages";

// WEB-B1–B3 against the production build (see playwright.config.ts).

test("pages send the strict CSP and baseline headers", async ({ page }) => {
  const response = await page.goto("/");
  const headers = response!.headers();

  const csp = headers["content-security-policy"];
  expect(csp).toMatch(/script-src 'self' 'nonce-[^']+' 'strict-dynamic'/);
  expect(csp).not.toContain("unsafe-inline");
  expect(csp).toContain("frame-ancestors 'none'");
  expect(headers["strict-transport-security"]).toBe("max-age=63072000; includeSubDomains");
  expect(headers["x-content-type-options"]).toBe("nosniff");
  expect(headers["x-frame-options"]).toBe("DENY");
  expect(headers["x-powered-by"]).toBeUndefined();
});

test("every response gets a fresh nonce", async ({ request }) => {
  const nonceOf = async () =>
    (await request.get("/")).headers()["content-security-policy"].match(/'nonce-([^']+)'/)![1];

  expect(await nonceOf()).not.toBe(await nonceOf());
});

for (const { path } of publicPages) {
  test(`${path} runs under the CSP with no violations`, async ({ page }) => {
    const violations: string[] = [];
    page.on("console", (message) => {
      if (/Content Security Policy/i.test(message.text())) violations.push(message.text());
    });

    await page.goto(path);

    // React attaches its fiber keys to DOM nodes once it has hydrated the
    // page, which only happens if the framework scripts were allowed to run.
    await expect
      .poll(() =>
        page.evaluate(() => Object.keys(document.body).some((key) => key.startsWith("__react"))),
      )
      .toBe(true);
    await page.evaluate(() => document.fonts.ready);
    expect(violations).toEqual([]);
  });
}

test("portal paths are never cached", async ({ request }) => {
  const response = await request.get("/servers");

  expect(response.headers()["cache-control"]).toContain("no-store");
});
