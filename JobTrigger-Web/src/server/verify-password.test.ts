// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { verifyPassword } from "./auth-api";

vi.mock("./config", () => ({
  getConfig: () => ({ backendUrl: "http://backend.test", sessionSecret: "x", siteUrl: "" }),
}));

const fetchMock = vi.fn<typeof fetch>();
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

beforeEach(() => vi.stubGlobal("fetch", fetchMock));
afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
});

describe("verifyPassword", () => {
  it("posts the password to the backend's re-authentication check", async () => {
    fetchMock.mockResolvedValue(json({ message: "Password confirmed" }));

    expect((await verifyPassword("access-1", "pw")).ok).toBe(true);

    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe("http://backend.test/api/auth/verify-password");
    expect(init!.method).toBe("POST");
    expect(JSON.parse(String(init!.body))).toEqual({ password: "pw" });
    expect((init!.headers as Record<string, string>)["x-auth-token"]).toBe("access-1");
  });

  it("a wrong password is the backend's own message", async () => {
    fetchMock.mockResolvedValue(json({ message: "Current password is incorrect" }, 400));
    expect(await verifyPassword("t", "nope")).toEqual({
      ok: false,
      failure: { kind: "rejected", message: "Current password is incorrect" },
    });
  });
});
