// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { authed } from "./authed";
import { tokenExpiresAt } from "./jwt";
import { IDLE_TIMEOUT_MS, isIdle, isSignedIn, type Session } from "./session";

vi.mock("./config", () => ({
  getConfig: () => ({
    backendUrl: "http://backend.test",
    sessionSecret: "s".repeat(32),
    siteUrl: "",
  }),
}));

const fetchMock = vi.fn<typeof fetch>();
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

beforeEach(() => {
  vi.stubGlobal("fetch", fetchMock);
  vi.spyOn(console, "warn").mockImplementation(() => {});
});
afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

function fakeSession(): Session {
  const data = {
    accessToken: "old-access",
    refreshToken: "old-refresh",
    email: "sam@acme.dev",
    lastActivity: 0,
  };
  return Object.assign(data, {
    save: vi.fn(async () => {}),
    destroy: vi.fn(),
    updateConfig: vi.fn(),
  }) as Session;
}

const fail401 = { ok: false as const, failure: { kind: "auth" as const } };

describe("authed", () => {
  it("refreshes once on a 401, saves the new pair and replays the call", async () => {
    const session = fakeSession();
    fetchMock.mockResolvedValue(
      json({ token: "new-access", refreshToken: "new-refresh", user: { email: "sam@acme.dev" } }),
    );
    const call = vi
      .fn()
      .mockResolvedValueOnce(fail401)
      .mockResolvedValueOnce({ ok: true, value: "data" });

    expect(await authed(session, call)).toEqual({ ok: true, value: "data" });
    expect(call).toHaveBeenNthCalledWith(1, "old-access");
    expect(call).toHaveBeenNthCalledWith(2, "new-access");
    expect(session.refreshToken).toBe("new-refresh");
    expect(session.save).toHaveBeenCalledOnce();
  });

  it("ends the session when the refresh itself is refused", async () => {
    const session = fakeSession();
    fetchMock.mockResolvedValue(json({ message: "Session expired" }, 401));

    expect(await authed(session, vi.fn().mockResolvedValue(fail401))).toEqual(fail401);
    expect(session.destroy).toHaveBeenCalledOnce();
  });

  it("keeps the session when the refresh fails for another reason (NFR-SEC-07)", async () => {
    const session = fakeSession();
    fetchMock.mockRejectedValue(new TypeError("fetch failed"));

    expect(await authed(session, vi.fn().mockResolvedValue(fail401))).toEqual({
      ok: false,
      failure: { kind: "network" },
    });
    expect(session.destroy).not.toHaveBeenCalled();
  });

  it("doesn't refresh on other failures", async () => {
    const session = fakeSession();
    const call = vi.fn().mockResolvedValue({ ok: false, failure: { kind: "notFound" } });

    await authed(session, call);

    expect(fetchMock).not.toHaveBeenCalled();
    expect(call).toHaveBeenCalledOnce();
  });
});

describe("session helpers", () => {
  it("know when a session is signed in and when it's idle", () => {
    expect(isSignedIn({})).toBe(false);
    expect(isSignedIn({ accessToken: "a", refreshToken: "r", email: "e" })).toBe(true);
    expect(isIdle({ lastActivity: 0 }, IDLE_TIMEOUT_MS)).toBe(false);
    expect(isIdle({ lastActivity: 0 }, IDLE_TIMEOUT_MS + 1)).toBe(true);
  });

  it("read a JWT's expiry without verifying it", () => {
    const payload = Buffer.from(JSON.stringify({ exp: 1_800_000_000 })).toString("base64url");

    expect(tokenExpiresAt(`h.${payload}.s`)).toBe(1_800_000_000_000);
    expect(tokenExpiresAt("not-a-jwt")).toBeNull();
  });
});
