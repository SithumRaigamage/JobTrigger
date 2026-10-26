import { expect, test } from "@playwright/test";

// next/font self-hosts the fonts at build time; the browser must never
// contact Google (WEB-B2: the CSP will only allow 'self').
test("fonts load from this site, not Google", async ({ page }) => {
  const fontRequests: string[] = [];
  page.on("request", (request) => {
    if (
      request.resourceType() === "font" ||
      /fonts\.(googleapis|gstatic)\.com/.test(request.url())
    ) {
      fontRequests.push(request.url());
    }
  });

  await page.goto("/");
  await page.waitForLoadState("networkidle");

  expect(fontRequests.length).toBeGreaterThan(0);
  for (const url of fontRequests) {
    expect(new URL(url).origin).toBe(new URL(page.url()).origin);
  }
  expect(await page.evaluate(() => getComputedStyle(document.body).fontFamily)).toContain("Inter");
});
