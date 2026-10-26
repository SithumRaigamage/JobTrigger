import { expect, test } from "@playwright/test";

import { publicPages } from "./pages";

for (const { path, title } of publicPages) {
  test(`${path} loads with its title and one h1`, async ({ page }) => {
    await page.goto(path);

    await expect(page).toHaveTitle(title);
    await expect(page.getByRole("heading", { level: 1 })).toHaveCount(1);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  });
}
