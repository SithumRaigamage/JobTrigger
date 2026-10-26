// @vitest-environment node
import { sealData, unsealData } from "iron-session";
import { NextRequest } from "next/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { IDLE_TIMEOUT_MS, SESSION_COOKIE, type SessionData } from "./server/session";
import { upkeepSession } from "./session-upkeep";

const SECRET = "s".repeat(32);

vi.mock("./server/config", () => ({
  getConfig: () => ({ backendUrl: "http://backend.test", sessionSecret: SECRET, siteUrl: "" }),
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

const NOW = 1_800_000_000_000;

/** A JWT-shaped token that expires [inMs] from NOW. */
const token = (name: string, inMs: number) =>
  `h.${Buffer.from(JSON.stringify({ exp: (NOW + inMs) / 1000, n: name })).toString("base64url")}.s`;

async function requestWith(data: Partial<SessionData>) {
  const seal = await sealData(data, { password: SECRET });
  return new NextRequest("http://localhost/servers", {
    headers: { cookie: `${SESSION_COOKIE}=${seal}` },
  });
}

const signedIn = (overrides: Partial<SessionData> = {}): Partial<SessionData> => ({
  accessToken: token("access", 10 * 60_000),
  refreshToken: "refresh-1",
  email: "sam@acme.dev",
  lastActivity: NOW - 60_000,
  ...overrides,
});

async function sessionIn(request: NextRequest) {
  const value = request.cookies.get(SESSION_COOKIE)?.value;
  return value ? unsealData<SessionData>(value, { password: SECRET }) : null;
}

describe("upkeepSession", () => {
  it("only bumps last activity while the access token has time left", async () => {
    const request = await requestWith(signedIn());

    const cookies = await upkeepSession(request, NOW);

    expect(fetchMock).not.toHaveBeenCalled();
    expect(cookies).toHaveLength(1);
    expect((await sessionIn(request))?.lastActivity).toBe(NOW);
  });

  it("renews an access token about to expire, visible to this request's render", async () => {
    const renewed = token("renewed", 15 * 60_000);
    fetchMock.mockResolvedValue(
      json({ token: renewed, refreshToken: "refresh-2", user: { email: "sam@acme.dev" } }),
    );
    const request = await requestWith(signedIn({ accessToken: token("old", 30_000) }));

    await upkeepSession(request, NOW);

    expect(String(fetchMock.mock.calls[0][0])).toBe("http://backend.test/api/auth/refresh");
    expect(await sessionIn(request)).toMatchObject({
      accessToken: renewed,
      refreshToken: "refresh-2",
    });
  });

  it("signs out after 30 idle minutes", async () => {
    const request = await requestWith(signedIn({ lastActivity: NOW - IDLE_TIMEOUT_MS - 1 }));

    const cookies = await upkeepSession(request, NOW);

    expect(request.cookies.get(SESSION_COOKIE)).toBeUndefined();
    expect(cookies[0]).toMatchObject({ name: SESSION_COOKIE, value: "" });
  });

  it("signs out when the refresh token is refused", async () => {
    fetchMock.mockResolvedValue(json({ message: "Session expired" }, 401));
    const request = await requestWith(signedIn({ accessToken: token("old", 0) }));

    await upkeepSession(request, NOW);

    expect(request.cookies.get(SESSION_COOKIE)).toBeUndefined();
  });

  it("keeps the session when the refresh fails for another reason (NFR-SEC-07)", async () => {
    fetchMock.mockRejectedValue(new TypeError("fetch failed"));
    const request = await requestWith(signedIn({ accessToken: token("old", 0) }));

    await upkeepSession(request, NOW);

    expect(await sessionIn(request)).toMatchObject({ refreshToken: "refresh-1" });
  });

  it("does nothing without a session", async () => {
    const request = new NextRequest("http://localhost/servers");

    expect(await upkeepSession(request, NOW)).toEqual([]);
  });
});
