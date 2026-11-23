// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const createToolRequest = vi.fn();
const createSupportTicket = vi.fn();

vi.mock("@/server/guard", () => ({
  requireSession: async () => ({ accessToken: "a", email: "sam@acme.dev" }),
}));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/support-api", () => ({
  createToolRequest: (...args: unknown[]) => createToolRequest(...args),
  createSupportTicket: (...args: unknown[]) => createSupportTicket(...args),
}));

import { requestToolAction, submitSupportAction } from "./actions";

const form = (fields: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(fields)) data.set(key, value);
  return data;
};

beforeEach(() => {
  createToolRequest.mockReset();
  createSupportTicket.mockReset();
});

// US-WEB-04 (owner decision 2026-11-21).
describe("requestToolAction", () => {
  it("files the request and says where the reply goes", async () => {
    createToolRequest.mockResolvedValue({ ok: true, value: { id: "t9" } });

    const state = await requestToolAction(
      {},
      form({ subject: " Tool request: Buildkite ", message: "We use it." }),
    );

    expect(createToolRequest).toHaveBeenCalledWith(
      "access-1",
      "Tool request: Buildkite",
      "We use it.",
    );
    expect(state).toEqual({ sent: { ticketId: "t9", replyEmail: "sam@acme.dev" } });
  });

  it("checks the form first, with the app's copy, and keeps what was typed", async () => {
    const state = await requestToolAction({}, form({ subject: "Tool request: X", message: " " }));

    expect(createToolRequest).not.toHaveBeenCalled();
    expect(state).toMatchObject({
      error: "Describe the issue or request.",
      subject: "Tool request: X",
    });
  });

  it("shows the backend's refusal and keeps the text", async () => {
    createToolRequest.mockResolvedValue({ ok: false, failure: { kind: "network" } });

    const state = await requestToolAction({}, form({ subject: "S", message: "M" }));

    expect(state).toMatchObject({
      error: "Can't reach the server. Check your connection and try again.",
      message: "M",
    });
  });
});

const PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==",
  "base64",
);

const richForm = (screenshots: File[] = []) => {
  const data = form({
    category: "bug",
    subject: "Blank log",
    message: " Nothing shows. ",
    impact: "blocked",
  });
  data.append("areas", "jenkins");
  data.append("areas", "phone");
  for (const file of screenshots) data.append("screenshots", file);
  return data;
};

// US-SUP-05/06: the signed-in form files the same rich ticket as the app.
describe("submitSupportAction", () => {
  it("sends the options and a base64 screenshot, then reports the ticket", async () => {
    createSupportTicket.mockResolvedValue({ ok: true, value: { id: "t31" } });
    const shot = new File([PNG], "shot.png", { type: "image/png" });

    const state = await submitSupportAction({}, richForm([shot]));

    expect(createSupportTicket).toHaveBeenCalledWith("access-1", {
      category: "bug",
      subject: "Blank log",
      message: "Nothing shows.",
      areas: ["jenkins", "phone"],
      impact: "blocked",
      replyEmail: "sam@acme.dev",
      screenshots: [{ name: "shot.png", data: PNG.toString("base64") }],
    });
    expect(state).toEqual({ sent: { ticketId: "t31", replyEmail: "sam@acme.dev" } });
  });

  it("accepts a report with no screenshots", async () => {
    createSupportTicket.mockResolvedValue({ ok: true, value: { id: "t32" } });
    await submitSupportAction({}, richForm());
    expect(createSupportTicket.mock.calls[0]![1]).toMatchObject({ screenshots: [] });
  });

  it("refuses a bad image by its bytes, keeping the text for a retry", async () => {
    const fake = new File([Buffer.from("not an image")], "shot.png", { type: "image/png" });
    const state = await submitSupportAction({}, richForm([fake]));
    expect(createSupportTicket).not.toHaveBeenCalled();
    expect(state).toMatchObject({
      error: "Screenshots must be JPG or PNG images.",
      subject: "Blank log",
      areas: ["jenkins", "phone"],
    });
  });

  it("refuses too many or oversized files before anything travels", async () => {
    const shots = Array.from(
      { length: 4 },
      (_, index) => new File([PNG], `shot-${index}.png`, { type: "image/png" }),
    );
    expect((await submitSupportAction({}, richForm(shots))).error).toContain("at most 3");

    const huge = new File([new Uint8Array(5 * 1024 * 1024 + 1)], "huge.png", {
      type: "image/png",
    });
    expect((await submitSupportAction({}, richForm([huge]))).error).toContain("5 MB");
    expect(createSupportTicket).not.toHaveBeenCalled();
  });

  it("checks the text options and shows the backend's refusal", async () => {
    const bad = richForm();
    bad.set("category", "retired_kind");
    expect((await submitSupportAction({}, bad)).error).toBe("Choose what kind of report this is.");

    createSupportTicket.mockResolvedValue({
      ok: false,
      failure: { kind: "rejected", message: "Choose a known impact." },
    });
    const state = await submitSupportAction({}, richForm());
    // A refused send keeps exactly what was typed, as the tool form does.
    expect(state).toMatchObject({ error: "Choose a known impact.", message: " Nothing shows. " });
  });
});
