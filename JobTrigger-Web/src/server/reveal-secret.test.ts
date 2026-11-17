// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { revealSecret } from "./credentials-api";

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

describe("revealSecret", () => {
  it.each([
    ["jenkins", "/api/credentials/j1/secret", { password: "pw-1", paramToken: null }, "pw-1"],
    ["github", "/api/github-credentials/j1/secret", { token: "gh-1" }, "gh-1"],
    ["sonarqube", "/api/sonarqube-credentials/j1/secret", { token: "sq-1" }, "sq-1"],
  ] as const)(
    "%s: asks the owner-only endpoint for that one credential",
    async (tool, path, body, secret) => {
      fetchMock.mockResolvedValue(json({ ...body, needsReentry: false, version: "v" }));

      expect(await revealSecret("access-1", tool, "j1")).toEqual({ ok: true, value: secret });

      expect(fetchMock).toHaveBeenCalledTimes(1);
      const [url, init] = fetchMock.mock.calls[0]!;
      expect(String(url)).toBe(`http://backend.test${path}`);
      expect(init!.method ?? "GET").toBe("GET");
      expect((init!.headers as Record<string, string>)["x-auth-token"]).toBe("access-1");
    },
  );

  it("returns null for a secret the backend couldn't decrypt", async () => {
    fetchMock.mockResolvedValue(json({ password: null, needsReentry: true }));
    expect(await revealSecret("t", "jenkins", "j1")).toEqual({ ok: true, value: null });
  });

  it("encodes the id so it can't change the path", async () => {
    fetchMock.mockResolvedValue(json({ token: "x" }));
    await revealSecret("t", "github", "../other");
    expect(String(fetchMock.mock.calls[0]![0])).toBe(
      "http://backend.test/api/github-credentials/..%2Fother/secret",
    );
  });

  it("reports the backend's rate limit, a foreign id and a locked credential as failures", async () => {
    fetchMock.mockResolvedValueOnce(json({ message: "slow down" }, 429));
    expect(await revealSecret("t", "jenkins", "j1")).toEqual({
      ok: false,
      failure: { kind: "server", status: 429 },
    });
    fetchMock.mockResolvedValueOnce(json({ message: "Not found" }, 404));
    expect(await revealSecret("t", "jenkins", "someone-else")).toEqual({
      ok: false,
      failure: { kind: "notFound" },
    });
    fetchMock.mockResolvedValueOnce(
      json({ code: "PLAN_LIMIT", limit: "locked", message: "x" }, 403),
    );
    expect(await revealSecret("t", "jenkins", "j2")).toEqual({
      ok: false,
      failure: { kind: "planLimit", limit: "locked" },
    });
  });
});
