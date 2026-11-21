import { expect, test } from "@playwright/test";

import { signUp } from "./flows";
import { uniqueEmail } from "./session";

// US-WEB-04 (owner decision 2026-11-21): signed out, "Request a tool" is the
// support email; signed in, it files a "Tool request" Support ticket.
const ticketsFor = async (email: string) =>
  (
    (await (
      await fetch(`http://127.0.0.1:5999/__stats?email=${encodeURIComponent(email)}`)
    ).json()) as { tickets: { category: string; subject: string }[] }
  ).tickets;

test("signed out, Request a tool is the support email", async ({ page }) => {
  await page.goto("/integrations");
  await expect(page.getByRole("link", { name: "Request a tool →" })).toHaveAttribute(
    "href",
    /^mailto:support@jobtrigger\.test/,
  );
});

test("signed in, Request a tool files a Tool request ticket", async ({ page }) => {
  const email = uniqueEmail();
  await signUp(page, email);
  await page.goto("/integrations");
  await page.getByRole("link", { name: "Request a tool →" }).click();
  await page.waitForURL(/\/account\/request-tool$/);

  await expect(page.getByLabel("Subject")).toHaveValue("Tool request: ");
  await page.getByLabel("Subject").fill("Tool request: Buildkite");
  await page.getByLabel("Details").fill("We run everything on Buildkite.");
  await page.getByRole("button", { name: "Send request" }).click();

  await expect(page.getByRole("heading", { name: "Request sent" })).toBeVisible();
  await expect(page.getByText(`We reply to ${email}.`)).toBeVisible();
  expect(await ticketsFor(email)).toEqual([
    expect.objectContaining({ category: "tool_request", subject: "Tool request: Buildkite" }),
  ]);
});

test("an empty request says what is missing and sends nothing", async ({ page }) => {
  const email = uniqueEmail();
  await signUp(page, email);
  await page.goto("/account/request-tool");
  await page.getByRole("button", { name: "Send request" }).click();

  await expect(page.getByRole("alert")).toHaveText("Describe the issue or request.");
  expect(await ticketsFor(email)).toEqual([]);
});
