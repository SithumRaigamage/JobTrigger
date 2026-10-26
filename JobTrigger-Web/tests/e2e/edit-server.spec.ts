import { expect, test, type Page } from "@playwright/test";

import { backendToken, seed } from "./backend";
import { PASSWORD, signUp } from "./flows";

const TOKEN = "fake-jenkins-token-a91f";
const NEW_TOKEN = "fake-jenkins-token-b72e";

async function withJenkins(page: Page) {
  const email = await signUp(page);
  const token = await backendToken(email, PASSWORD);
  const saved = await seed(token, "/api/credentials", {
    serverName: "Acme production",
    jenkinsURL: "https://ci.acme.dev",
    username: "sam",
    password: TOKEN,
    isDefault: true,
  });
  return { token, id: saved._id };
}

test("editing with a blank token keeps the saved one", async ({ page }) => {
  await withJenkins(page);
  await page.goto("/servers");
  await page.getByRole("link", { name: "Edit Acme production" }).click();

  await expect(page.getByLabel("API token", { exact: true })).toHaveValue("");
  await expect(page.getByText("Leave blank to keep the saved token.")).toBeVisible();
  await page.getByLabel("Name", { exact: true }).fill("Acme prod");
  await page.getByRole("button", { name: "Save changes" }).click();

  await page.waitForURL(/\/servers$/);
  await expect(page.getByRole("rowheader", { name: /Acme prod/ })).toBeVisible();
  await expect(page.getByText("••••a91f")).toBeVisible();
});

test("pasting a new token rotates it", async ({ page }) => {
  const { id } = await withJenkins(page);
  await page.goto(`/servers/jenkins/${id}`);

  await page.getByLabel("API token", { exact: true }).fill(NEW_TOKEN);
  await page.getByRole("button", { name: "Save changes" }).click();

  await page.waitForURL(/\/servers$/);
  await expect(page.getByText("••••b72e")).toBeVisible();
});

test("delete asks first, naming the server, and Cancel is the default", async ({ page }) => {
  const { id } = await withJenkins(page);
  await page.goto(`/servers/jenkins/${id}`);

  await page.getByRole("button", { name: "Delete server" }).click();
  const dialog = page.getByRole("dialog", { name: "Delete “Acme production”?" });
  await expect(dialog).toBeVisible();
  await expect(dialog.getByRole("button", { name: "Cancel" })).toBeFocused();
  await dialog.getByRole("button", { name: "Delete server" }).click();

  await page.waitForURL(/\/servers$/);
  await expect(page.getByRole("heading", { name: "No servers yet" })).toBeVisible();
});

test("a server deleted elsewhere reads as not found", async ({ page }) => {
  const { token, id } = await withJenkins(page);
  await fetch(`http://127.0.0.1:5999/api/credentials/${id}`, {
    method: "DELETE",
    headers: { "x-auth-token": token },
  });

  await page.goto(`/servers/jenkins/${id}`);

  await expect(page.getByText("That couldn't be found — it may have been removed.")).toBeVisible();
  await expect(page.getByRole("link", { name: "Back to my servers →" })).toBeVisible();
});
