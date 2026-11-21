// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const createToolRequest = vi.fn();

vi.mock("@/server/guard", () => ({
  requireSession: async () => ({ accessToken: "a", email: "sam@acme.dev" }),
}));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/support-api", () => ({
  createToolRequest: (...args: unknown[]) => createToolRequest(...args),
}));

import { requestToolAction } from "./actions";

const form = (fields: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(fields)) data.set(key, value);
  return data;
};

beforeEach(() => createToolRequest.mockReset());

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
