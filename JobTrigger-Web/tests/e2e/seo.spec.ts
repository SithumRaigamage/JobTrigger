import { expect, test } from "@playwright/test";

import { publicPages } from "./pages";

// US-WEB-07 against the production build (SITE_URL from playwright.config).

for (const { path } of publicPages) {
  test(`${path} has a description, canonical URL and preview tags`, async ({ page, baseURL }) => {
    await page.goto(path);
    const meta = (selector: string) => page.locator(selector).first().getAttribute("content");

    expect(await meta('meta[name="description"]')).toBeTruthy();
    expect(await page.locator('link[rel="canonical"]').getAttribute("href")).toBe(
      path === "/" ? baseURL : `${baseURL}${path}`,
    );
    expect(await meta('meta[property="og:title"]')).toBeTruthy();
    expect(await meta('meta[property="og:image"]')).toMatch(
      /^http:\/\/localhost:\d+\/opengraph-image/,
    );
    expect(await meta('meta[name="twitter:card"]')).toBe("summary_large_image");
  });
}

test("descriptions are unique per page", async ({ page }) => {
  const descriptions = new Set<string>();
  for (const { path } of publicPages) {
    await page.goto(path);
    descriptions.add((await page.locator('meta[name="description"]').getAttribute("content"))!);
  }
  expect(descriptions.size).toBe(publicPages.length);
});

test("the preview image is a 1200×630 PNG", async ({ request }) => {
  const response = await request.get("/opengraph-image");

  expect(response.status()).toBe(200);
  expect(response.headers()["content-type"]).toBe("image/png");
  const png = await response.body();
  expect(png.readUInt32BE(16)).toBe(1200);
  expect(png.readUInt32BE(20)).toBe(630);
});

test("robots.txt disallows the portal and points to the sitemap", async ({ request, baseURL }) => {
  const text = await (await request.get("/robots.txt")).text();

  for (const path of ["/sign-in", "/sign-up", "/servers", "/account"]) {
    expect(text).toContain(`Disallow: ${path}`);
  }
  expect(text).toContain(`Sitemap: ${baseURL}/sitemap.xml`);
});

test("the sitemap lists public pages only, at the runtime SITE_URL", async ({
  request,
  baseURL,
}) => {
  const xml = await (await request.get("/sitemap.xml")).text();

  expect(xml).toContain(`<loc>${baseURL}/security</loc>`);
  expect(xml).not.toMatch(/sign-in|servers|account/);
});

test("portal paths are marked noindex", async ({ request }) => {
  const response = await request.get("/servers", { maxRedirects: 0 });

  expect(response.headers()["x-robots-tag"]).toBe("noindex, nofollow");
});
