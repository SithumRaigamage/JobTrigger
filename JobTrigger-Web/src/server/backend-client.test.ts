// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { z } from "zod";

import { callBackend, failureFor } from "./backend-client";

vi.mock("./config", () => ({
  getConfig: () => ({ backendUrl: "http://backend.test", sessionSecret: "x", siteUrl: "" }),
}));

const fetchMock = vi.fn<typeof fetch>();
const json = (body: unknown, status = 200, headers: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...headers },
  });

beforeEach(() => {
  vi.stubGlobal("fetch", fetchMock);
  vi.spyOn(console, "warn").mockImplementation(() => {});
});
afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("failureFor", () => {
  it("maps statuses like the app does", () => {
    expect(failureFor(401, { message: "Token is not valid" }, null)).toEqual({ kind: "auth" });
    expect(failureFor(404, {}, null)).toEqual({ kind: "notFound" });
    expect(failureFor(400, { message: "User already exists" }, null)).toEqual({
      kind: "rejected",
      message: "User already exists",
    });
    expect(failureFor(429, {}, "req-1")).toEqual({
      kind: "server",
      status: 429,
      requestId: "req-1",
    });
    expect(failureFor(500, {}, "bad id with spaces")).toEqual({ kind: "server", status: 500 });
  });
});

describe("callBackend", () => {
  it("sends x-auth-token (not Bearer) and a 16-hex x-request-id", async () => {
    fetchMock.mockResolvedValue(json({ ok: true }));

    await callBackend(
      { path: "/api/credentials", accessToken: "access-1" },
      z.object({ ok: z.boolean() }),
    );

    const [url, init] = fetchMock.mock.calls[0];
    const headers = init!.headers as Record<string, string>;
    expect(url).toBe("http://backend.test/api/credentials");
    expect(headers["x-auth-token"]).toBe("access-1");
    expect(headers.authorization).toBeUndefined();
    expect(headers["x-request-id"]).toMatch(/^[0-9a-f]{16}$/);
  });

  it("sends JSON bodies", async () => {
    fetchMock.mockResolvedValue(json({ ok: true }));

    await callBackend(
      { method: "POST", path: "/api/auth/login", body: { email: "a@b.co", password: "pw" } },
      z.object({ ok: z.boolean() }),
    );

    const init = fetchMock.mock.calls[0][1]!;
    expect(init.method).toBe("POST");
    expect(init.body).toBe('{"email":"a@b.co","password":"pw"}');
  });

  it("is a NetworkFailure when the backend can't be reached", async () => {
    fetchMock.mockRejectedValue(new TypeError("fetch failed"));

    expect(await callBackend({ path: "/api/appinfo" }, z.object({}))).toEqual({
      ok: false,
      failure: { kind: "network" },
    });
  });

  it("is an UnexpectedResponseFailure when the shape is wrong, e.g. an HTML login page", async () => {
    fetchMock.mockResolvedValue(new Response("<html>sign in</html>", { status: 200 }));

    expect(await callBackend({ path: "/api/credentials" }, z.array(z.object({})))).toEqual({
      ok: false,
      failure: { kind: "unexpected" },
    });
  });

  it("never logs request bodies or tokens", async () => {
    fetchMock.mockResolvedValue(json({ message: "Server error" }, 500));

    await callBackend(
      {
        method: "POST",
        path: "/api/auth/login",
        body: { password: "hunter2-secret" },
        accessToken: "tok-secret",
      },
      z.object({}),
    );

    const logged = vi.mocked(console.warn).mock.calls.flat().join(" ");
    expect(logged).not.toContain("hunter2-secret");
    expect(logged).not.toContain("tok-secret");
  });
});
