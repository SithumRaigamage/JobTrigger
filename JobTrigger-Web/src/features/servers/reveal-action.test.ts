// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const verifyPassword = vi.fn();
const revealSecret = vi.fn();

vi.mock("next/cache", () => ({ revalidatePath: vi.fn() }));
vi.mock("next/navigation", () => ({ redirect: vi.fn() }));
vi.mock("@/server/guard", () => ({ requireSession: async () => ({ accessToken: "a" }) }));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/auth-api", () => ({
  verifyPassword: (...args: unknown[]) => verifyPassword(...args),
}));
vi.mock("@/server/credentials-api", () => ({
  revealSecret: (...args: unknown[]) => revealSecret(...args),
}));
vi.mock("@/server/analytics", () => ({ track: vi.fn() }));

import { revealSecretAction } from "./actions";

const target = { tool: "jenkins", id: "abc123" } as const;

beforeEach(() => {
  verifyPassword.mockReset();
  revealSecret.mockReset();
});

describe("revealSecretAction", () => {
  it("confirms the password first, then reveals", async () => {
    verifyPassword.mockResolvedValue({ ok: true, value: {} });
    revealSecret.mockResolvedValue({ ok: true, value: "the-secret" });

    expect(await revealSecretAction(target, "right")).toEqual({ secret: "the-secret" });

    expect(verifyPassword).toHaveBeenCalledWith("access-1", "right");
    expect(verifyPassword.mock.invocationCallOrder[0]).toBeLessThan(
      revealSecret.mock.invocationCallOrder[0]!,
    );
    expect(revealSecret).toHaveBeenCalledWith("access-1", "jenkins", "abc123");
  });

  it("a wrong password shows the backend's message and never requests the secret", async () => {
    verifyPassword.mockResolvedValue({
      ok: false,
      failure: { kind: "rejected", message: "Current password is incorrect" },
    });

    expect(await revealSecretAction(target, "wrong")).toEqual({
      error: "Current password is incorrect",
    });
    expect(revealSecret).not.toHaveBeenCalled();
  });

  it("an empty password never reaches the backend", async () => {
    expect(await revealSecretAction(target, "")).toEqual({ error: "Enter your password." });
    expect(verifyPassword).not.toHaveBeenCalled();
    expect(revealSecret).not.toHaveBeenCalled();
  });

  it("rate limiting on the check is reported and also reveals nothing", async () => {
    verifyPassword.mockResolvedValue({ ok: false, failure: { kind: "server", status: 429 } });
    expect(await revealSecretAction(target, "x")).toEqual({
      error: "Too many attempts. Please wait a few minutes and try again.",
    });
    expect(revealSecret).not.toHaveBeenCalled();
  });

  it("still refuses a malformed target before anything else", async () => {
    expect(await revealSecretAction({ tool: "jenkins", id: "../x" }, "p")).toEqual({
      error: "That server couldn't be found.",
    });
    expect(verifyPassword).not.toHaveBeenCalled();
  });
});
