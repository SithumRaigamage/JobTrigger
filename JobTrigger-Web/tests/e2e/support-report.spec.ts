import { expect, test } from "@playwright/test";

import { signUp } from "./flows";
import { uniqueEmail } from "./session";

/*
 * US-SUP-05/06/07: the signed-in rich report and the owner's review console.
 * The fake backend stores tickets globally and their screenshot bytes in
 * memory; the owner account is any `student-admin-*` email (see fake-backend).
 */

const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3, 4]);
const shot = () => ({ name: "shot.png", mimeType: "image/png", buffer: PNG });

const ticketsFor = async (email: string) =>
  (
    (await (
      await fetch(`http://127.0.0.1:5999/__stats?email=${encodeURIComponent(email)}`)
    ).json()) as { tickets: { id: string; category: string; subject: string }[] }
  ).tickets;

test("signed out, support keeps the FAQ and shows no report form", async ({ page }) => {
  await page.goto("/support");
  await expect(page.getByRole("heading", { name: "How can we help?" })).toBeVisible();
  await expect(page.getByText("Jenkins says my credentials are wrong")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Send a report" })).toHaveCount(0);
});

test("a signed-in report with options and a screenshot reaches the owner console", async ({
  page,
  browser,
}) => {
  const email = uniqueEmail();
  const subject = `Blank log ${uniqueEmail()}`; // the queue is global across parallel workers
  await signUp(page, email);
  await page.goto("/support");

  const form = page.locator("#send-report");
  await expect(form.getByRole("heading", { name: "Send a report" })).toBeVisible();
  await page.getByLabel("Bug").check();
  await page.getByLabel("GitHub Actions").check();
  await page.getByLabel("Phone/app").check();
  await page.getByLabel("Impact").selectOption("blocked");
  await page.getByLabel("Subject").fill(subject);
  await page.getByLabel("Details").fill("Nothing shows after five minutes.");
  await page.getByLabel(/Screenshots/).setInputFiles(shot());
  await expect(page.getByText("Remove shot.png")).toBeVisible();
  await page.getByRole("button", { name: "Send report" }).click();

  await expect(page.getByRole("heading", { name: "Report sent" })).toBeVisible();
  const stored = await ticketsFor(email);
  expect(stored).toEqual([expect.objectContaining({ category: "bug", subject })]);
  const id = stored[0]!.id;
  await expect(page.getByText(`Ticket ${id}`)).toBeVisible();

  // The owner sees it in the queue, with triage signals but no email images.
  const adminContext = await browser.newContext({ baseURL: test.info().project.use.baseURL });
  const adminPage = await adminContext.newPage();
  await signUp(adminPage, uniqueEmail("student-admin"));
  await adminPage.goto("/admin/support");
  await expect(adminPage.getByRole("heading", { name: "Support reports" })).toBeVisible();
  const row = adminPage.locator(`li:has(a[href="/admin/support/${id}"])`);
  await expect(row.getByText(subject)).toBeVisible();
  await expect(row.getByText(/GitHub Actions, Phone\/app · Blocked/)).toBeVisible();
  await expect(row.getByText(/1 screenshot · Open/)).toBeVisible();

  await row.getByRole("link", { name: "Open" }).click();
  await expect(adminPage.getByText("Nothing shows after five minutes.")).toBeVisible();
  await expect(adminPage.getByText("Jenkins")).toHaveCount(0); // not selected here
  await expect(adminPage.getByText("GitHub Actions, Phone/app")).toBeVisible();

  const image = adminPage.getByRole("img", { name: "Screenshot 1" });
  await expect(image).toBeVisible();
  const src = (await image.getAttribute("src"))!;
  const response = await adminPage.request.get(src);
  expect(response.status()).toBe(200);
  expect(response.headers()["content-type"]).toBe("image/png");
  expect(response.headers()["cache-control"]).toBe("no-store");

  await adminPage.getByLabel("Status").selectOption("closed");
  await adminPage.getByRole("button", { name: "Save status" }).click();
  await expect(adminPage.getByRole("status")).toContainText("Marked closed.");
  await adminContext.close();
});

test("a normal account gets a plain 404 for the owner's support pages", async ({ page }) => {
  await signUp(page, uniqueEmail());
  expect((await page.goto("/admin/support"))?.status()).toBe(404);
  expect((await page.goto("/admin/support/64b0000000000000000000aa"))?.status()).toBe(404);
  const image = await page.request.get("/admin/support/64b0000000000000000000aa/screenshots/0");
  expect(image.status()).toBe(404);
});
