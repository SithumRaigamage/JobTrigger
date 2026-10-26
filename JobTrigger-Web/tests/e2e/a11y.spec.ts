import { expect, test, type Page } from "@playwright/test";

import { signUp } from "./flows";
import { publicPages } from "./pages";

/*
 * WEB-B4 / WEB-B5 checks on every page, public and portal. Not a full
 * audit (no axe dependency); the structural rules a page must never break.
 */

async function audit(page: Page) {
  const problems = await page.evaluate(() => {
    const out: string[] = [];
    if (!document.documentElement.lang) out.push("<html> has no lang");
    if (document.documentElement.scrollWidth > innerWidth) out.push("page scrolls sideways");
    if (document.querySelectorAll("h1").length !== 1)
      out.push(`${document.querySelectorAll("h1").length} h1s`);
    if (document.querySelectorAll("main").length !== 1) out.push("not exactly one <main>");

    const name = (el: Element) =>
      (el.getAttribute("aria-label") ?? "").trim() ||
      (el.getAttribute("aria-labelledby") ?? "").trim() ||
      (el.textContent ?? "").trim() ||
      (el.querySelector("img[alt]")?.getAttribute("alt") ?? "").trim();
    for (const el of document.querySelectorAll("a[href], button")) {
      if (!name(el)) out.push(`unnamed ${el.tagName.toLowerCase()}: ${el.outerHTML.slice(0, 80)}`);
    }
    for (const input of document.querySelectorAll("input:not([type=hidden]), select, textarea")) {
      const labelled =
        (input.id && document.querySelector(`label[for="${input.id}"]`)) ||
        input.getAttribute("aria-label") ||
        input.getAttribute("aria-labelledby") ||
        input.closest("label");
      if (!labelled) out.push(`unlabelled input: ${input.outerHTML.slice(0, 80)}`);
    }
    for (const img of document.querySelectorAll("img")) {
      if (!img.hasAttribute("alt")) out.push(`img without alt: ${img.getAttribute("src")}`);
    }
    return out;
  });
  expect(problems).toEqual([]);
}

for (const { path } of publicPages) {
  test(`${path} passes the structural accessibility checks`, async ({ page }) => {
    await page.goto(path);
    await audit(page);
  });
}

for (const path of ["/sign-in", "/sign-up"]) {
  test(`${path} passes the structural accessibility checks`, async ({ page }) => {
    await page.goto(path);
    await audit(page);
  });
}

test("portal pages pass the structural accessibility checks", async ({ page }) => {
  await signUp(page);
  for (const path of [
    "/servers",
    "/servers/new",
    "/servers/new?tool=github",
    "/servers/new?tool=sonarqube",
    "/account",
  ]) {
    await page.goto(path);
    await audit(page);
  }
});

test("the skip link is the first stop and lands on the content", async ({ page }) => {
  await page.goto("/features");

  await page.keyboard.press("Tab");
  const skip = page.getByRole("link", { name: "Skip to content" });
  await expect(skip).toBeFocused();
  await expect(skip).toBeVisible();
  await page.keyboard.press("Enter");
  await expect(page.locator("#content")).toBeFocused();
});
