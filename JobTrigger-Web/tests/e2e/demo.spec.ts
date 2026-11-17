import { expect, test } from "@playwright/test";

// E2 (PE-16): the public /demo page is the portal's My servers view on
// sample data, with no sign-in, no backend request and no server action.

test("/demo shows sample servers with masked tokens and inert controls", async ({ page }) => {
  await page.goto("/demo");

  await expect(page.getByRole("heading", { level: 1, name: "My servers" })).toBeVisible();
  const table = page.getByRole("region", { name: "Servers" });
  await expect(table.getByRole("rowheader", { name: /^Demo Jenkins Jenkins/ })).toBeVisible();
  await expect(table.getByRole("rowheader", { name: /^Demo GitHub/ })).toBeVisible();
  await expect(table.getByRole("rowheader", { name: /^Demo SonarQube/ })).toBeVisible();
  await expect(table.getByText("••••0001")).toBeVisible();

  // Shown, but not wired to anything.
  const addServer = page.getByRole("button", { name: "Add server" });
  await expect(addServer).toHaveAttribute("aria-disabled", "true");
  await expect(page.locator("main form")).toHaveCount(0);
  await expect(page.locator('main a[href^="/servers"]')).toHaveCount(0);
});

test("/demo makes no request to the backend and sets no cookie", async ({ page, context }) => {
  const requests: string[] = [];
  page.on("request", (request) => requests.push(request.url()));

  await page.goto("/demo");
  await page.getByRole("button", { name: "Add server" }).click({ force: true });
  await page
    .getByRole("button", { name: /^Make active/ })
    .first()
    .click({ force: true });
  await page.waitForLoadState("networkidle");

  // Only this site's own pages and assets: no fake backend (port 5999), no
  // other origin, and nothing posted.
  expect(requests.filter((url) => url.includes(":5999") || url.includes("/api/"))).toEqual([]);
  expect(
    requests.filter((url) => !new URL(url).origin.startsWith("http://localhost:3100")),
  ).toEqual([]);
  expect(await context.cookies()).toEqual([]);
});

test("the home page links to the demo", async ({ page }) => {
  await page.goto("/");
  await page
    .getByRole("link", { name: /See the demo/ })
    .first()
    .click();
  await expect(page).toHaveURL(/\/demo$/);
});
