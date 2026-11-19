import { expect, test, type Page } from "@playwright/test";

import { signUp } from "./flows";
import { uniqueEmail } from "./session";

/*
 * Phase 21: the student plan, against the fake backend (tests/e2e/
 * fake-backend.mjs): accounts named student-* have billing on and are on
 * Free, student-admin-* is a super admin, and the code is always 123456.
 */

const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3, 4]);
const png = (name = "id.png") => ({ name, mimeType: "image/png", buffer: PNG });

async function openCard(page: Page) {
  await page.goto("/account");
  const card = page.getByRole("region", { name: "Student verification" });
  await expect(card).toBeVisible();
  return card;
}

test("billing off: the account page has no student card", async ({ page }) => {
  await signUp(page);
  await page.goto("/account");
  await expect(page.getByRole("heading", { name: "Account", level: 1 })).toBeVisible();
  await expect(page.getByRole("region", { name: "Student verification" })).toHaveCount(0);
});

test("a listed university email: wrong code, then the right one, gives Pro", async ({ page }) => {
  await signUp(page, uniqueEmail("student"));
  const card = await openCard(page);

  await card.getByLabel("University email").fill("kasun@cse.uom.ac.lk");
  await card.getByRole("button", { name: "Send code" }).click();
  await expect(card.getByText(/We sent a 6-digit code to/)).toBeVisible();

  await card.getByLabel("Code").fill("000000");
  await card.getByRole("button", { name: "Verify" }).click();
  await expect(card.getByText("That code is not right. 4 tries left.")).toBeVisible();

  await card.getByLabel("Code").fill("123456");
  await card.getByRole("button", { name: "Verify" }).click();
  await expect(card.getByText(/You have JobTrigger Pro as a student/)).toBeVisible();
  // The plan card now names the student plan.
  await expect(page.getByRole("region", { name: "Plan", exact: true })).toContainText(
    "You're on Pro through the student plan.",
  );
});

test("a domain that is not listed falls back to a document, checked in the browser", async ({
  page,
}) => {
  await signUp(page, uniqueEmail("student"));
  const card = await openCard(page);

  await card.getByLabel("University email").fill("someone@gmail.com");
  await card.getByRole("button", { name: "Send code" }).click();
  await expect(card.getByText(/can't check that email domain automatically/)).toBeVisible();

  // A text file is refused before anything is sent.
  await card.getByLabel("Student ID or enrolment letter").setInputFiles({
    name: "notes.txt",
    mimeType: "text/plain",
    buffer: Buffer.from("hello"),
  });
  await expect(card.getByText("Only JPG, PNG or PDF files are accepted")).toBeVisible();

  await card.getByLabel("Full name as on your student ID").fill("Kasun Perera");
  await card.getByLabel("Student ID or enrolment letter").setInputFiles(png());
  await expect(card.getByText("Selected: id.png")).toBeVisible();
  await card.getByRole("button", { name: "Send for review" }).click();
  await expect(card.getByText("Pending review")).toBeVisible();
});

test("an admin reviews the document and approves it; the student sees the year", async ({
  page,
  browser,
}) => {
  const studentEmail = uniqueEmail("student");
  await signUp(page, studentEmail);
  const card = await openCard(page);
  await card.getByRole("button", { name: /Upload a student ID/ }).click();
  await card.getByLabel("Full name as on your student ID").fill("Nimali Silva");
  await card.getByLabel("Student ID or enrolment letter").setInputFiles(png());
  await card.getByRole("button", { name: "Send for review" }).click();
  await expect(card.getByText("Pending review")).toBeVisible();

  const adminContext = await browser.newContext({ baseURL: test.info().project.use.baseURL });
  const adminPage = await adminContext.newPage();
  await signUp(adminPage, uniqueEmail("student-admin"));

  await adminPage.goto(`/admin/students?q=${encodeURIComponent(studentEmail)}`);
  await expect(adminPage.getByText("Nimali Silva")).toBeVisible();
  await adminPage.getByRole("link", { name: "Review" }).click();

  // The document is shown from our own route, never cached.
  const image = adminPage.getByRole("img", { name: /uploaded document/ });
  await expect(image).toBeVisible();
  const src = (await image.getAttribute("src"))!;
  const response = await adminPage.request.get(src);
  expect(response.status()).toBe(200);
  expect(response.headers()["cache-control"]).toBe("no-store");
  expect(response.headers()["x-content-type-options"]).toBe("nosniff");
  expect(response.headers()["content-type"]).toBe("image/png");

  await adminPage.getByRole("button", { name: "Approve" }).click();
  await expect(adminPage.getByRole("status")).toContainText("Approved. The student has Pro");
  await adminContext.close();

  await page.goto("/account");
  await expect(page.getByRole("region", { name: "Student verification" })).toContainText(
    "You have JobTrigger Pro as a student",
  );
});

test("a rejection shows the reason and lets the student try again", async ({ page, browser }) => {
  const studentEmail = uniqueEmail("student");
  await signUp(page, studentEmail);
  const card = await openCard(page);
  await card.getByRole("button", { name: /Upload a student ID/ }).click();
  await card.getByLabel("Full name as on your student ID").fill("Amal Fernando");
  await card.getByLabel("Student ID or enrolment letter").setInputFiles(png());
  await card.getByRole("button", { name: "Send for review" }).click();
  await expect(card.getByText("Pending review")).toBeVisible();

  const adminContext = await browser.newContext({ baseURL: test.info().project.use.baseURL });
  const adminPage = await adminContext.newPage();
  await signUp(adminPage, uniqueEmail("student-admin"));
  await adminPage.goto(`/admin/students?q=${encodeURIComponent(studentEmail)}`);
  await adminPage.getByRole("link", { name: "Review" }).click();
  await adminPage.getByLabel(/Reason/).fill("The photo is too blurry to read.");
  await adminPage.getByRole("button", { name: "Reject" }).click();
  await expect(adminPage.getByRole("status")).toContainText("Rejected.");
  await adminContext.close();

  await page.goto("/account");
  const again = page.getByRole("region", { name: "Student verification" });
  await expect(again).toContainText("The photo is too blurry to read.");
  await again.getByRole("button", { name: "Try again" }).click();
  await expect(again.getByLabel("University email")).toBeVisible();
});

test("anyone who is not an admin gets a 404 for the admin pages and the document", async ({
  page,
}) => {
  await signUp(page, uniqueEmail("student"));

  const list = await page.goto("/admin/students");
  expect(list?.status()).toBe(404);
  const detail = await page.goto("/admin/students/64b0000000000000000000aa");
  expect(detail?.status()).toBe(404);
  const file = await page.request.get("/admin/students/64b0000000000000000000aa/document");
  expect(file.status()).toBe(404);
  // The admin pages are never indexed or cached.
  const headers = (await page.request.get("/admin/students")).headers();
  expect(headers["cache-control"]).toContain("no-store");
  expect(headers["x-robots-tag"]).toContain("noindex");
});

test("signed out, the admin document route is a 404 too", async ({ request }) => {
  const response = await request.get("/admin/students/64b0000000000000000000aa/document", {
    maxRedirects: 0,
  });
  expect([302, 303, 307, 308, 404]).toContain(response.status());
  expect(response.headers()["location"] ?? "").not.toContain("document");
});

test("/pricing shows the student offer while billing is on", async ({ page }) => {
  await page.goto("/pricing");
  // Release 1.0.0 enables billing, so Pro is on sale and the student offer is real.
  await expect(page.getByText(/Students get Pro free/)).toHaveCount(1);
});
