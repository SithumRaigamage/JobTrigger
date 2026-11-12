import { beforeEach, describe, expect, it, vi } from "vitest";

const api = vi.hoisted(() => ({
  requestPasswordReset: vi.fn(),
  confirmPasswordReset: vi.fn(),
}));
const destroy = vi.hoisted(() => vi.fn());

vi.mock("@/server/auth-api", () => api);
vi.mock("@/server/session", () => ({ getSession: async () => ({ destroy }) }));

import { forgotPasswordAction, resetPasswordAction } from "./password-reset-actions";

const form = (values: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(values)) data.set(key, value);
  return data;
};
const token = "a".repeat(64);

describe("forgotPasswordAction (US-AUTH-08)", () => {
  beforeEach(() => vi.resetAllMocks());

  it("checks the email before calling the backend", async () => {
    const state = await forgotPasswordAction({}, form({ email: "nope" }));
    expect(state.fields?.email).toBe("Enter a valid email address");
    expect(api.requestPasswordReset).not.toHaveBeenCalled();
  });

  it("reports sent, without saying whether the account exists", async () => {
    api.requestPasswordReset.mockResolvedValue({ ok: true, value: {} });
    const state = await forgotPasswordAction({}, form({ email: " sam@acme.dev " }));
    expect(api.requestPasswordReset).toHaveBeenCalledWith("sam@acme.dev");
    expect(state).toEqual({ sent: true, email: "sam@acme.dev" });
  });

  it("shows a backend failure", async () => {
    api.requestPasswordReset.mockResolvedValue({ ok: false, failure: { kind: "network" } });
    const state = await forgotPasswordAction({}, form({ email: "sam@acme.dev" }));
    expect(state.sent).toBeUndefined();
    expect(state.error).toBeTruthy();
  });
});

describe("resetPasswordAction (US-AUTH-08)", () => {
  beforeEach(() => vi.resetAllMocks());

  it("refuses a malformed token without calling the backend", async () => {
    const state = await resetPasswordAction(
      {},
      form({ token: "abc", password: "long-enough-1", confirm: "long-enough-1" }),
    );
    expect(state.error).toMatch(/invalid or has expired/);
    expect(api.confirmPasswordReset).not.toHaveBeenCalled();
  });

  it("checks the password rules first", async () => {
    const state = await resetPasswordAction(
      {},
      form({ token, password: "short", confirm: "other" }),
    );
    expect(state.fields?.password).toBe("Password must be at least 8 characters long");
    expect(state.fields?.confirm).toBe("Passwords don't match.");
    expect(api.confirmPasswordReset).not.toHaveBeenCalled();
  });

  it("resets, then ends this browser's session", async () => {
    api.confirmPasswordReset.mockResolvedValue({ ok: true, value: {} });
    const state = await resetPasswordAction(
      {},
      form({ token, password: "long-enough-1", confirm: "long-enough-1" }),
    );
    expect(api.confirmPasswordReset).toHaveBeenCalledWith(token, "long-enough-1");
    expect(destroy).toHaveBeenCalledOnce();
    expect(state).toEqual({ done: true });
  });

  it("never returns the token or the password in the state", async () => {
    api.confirmPasswordReset.mockResolvedValue({
      ok: false,
      failure: { kind: "rejected", message: "This reset link is invalid or has expired." },
    });
    const state = await resetPasswordAction(
      {},
      form({ token, password: "long-enough-1", confirm: "long-enough-1" }),
    );
    const serialized = JSON.stringify(state);
    expect(serialized).not.toContain(token);
    expect(serialized).not.toContain("long-enough-1");
    expect(destroy).not.toHaveBeenCalled();
  });
});
