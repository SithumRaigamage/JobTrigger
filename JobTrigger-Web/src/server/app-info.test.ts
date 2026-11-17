// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { getAppInfo, resetAppInfoCache } from "./app-info";

vi.mock("./config", () => ({
  getConfig: () => ({ backendUrl: "http://backend.test", sessionSecret: "x", siteUrl: "" }),
}));

const fetchMock = vi.fn<typeof fetch>();

beforeEach(() => {
  resetAppInfoCache();
  vi.stubGlobal("fetch", fetchMock);
  vi.spyOn(console, "warn").mockImplementation(() => {});
});

afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

describe("getAppInfo", () => {
  it("returns the support address from the backend", async () => {
    fetchMock.mockResolvedValue(json({ supportEmail: "help@jobtrigger.app", appVersion: "1.0.0" }));

    expect(await getAppInfo()).toEqual({ supportEmail: "help@jobtrigger.app" });
    expect(fetchMock).toHaveBeenCalledWith("http://backend.test/api/appinfo", expect.anything());
  });

  it("caches a success for five minutes", async () => {
    fetchMock.mockResolvedValue(json({ supportEmail: "help@jobtrigger.app" }));
    let time = 0;
    const now = () => time;

    await getAppInfo(now);
    time = 4 * 60_000;
    await getAppInfo(now);
    expect(fetchMock).toHaveBeenCalledTimes(1);

    time = 6 * 60_000;
    await getAppInfo(now);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it.each([
    [
      "a 404",
      () => fetchMock.mockResolvedValue(json({ message: "App information not found" }, 404)),
    ],
    ["a bad shape", () => fetchMock.mockResolvedValue(json({ supportEmail: "not-an-email" }))],
    ["a network error", () => fetchMock.mockRejectedValue(new TypeError("fetch failed"))],
  ])("is null on %s, without logging the response", async (_case, arrange) => {
    arrange();

    expect(await getAppInfo()).toBeNull();
    expect(console.warn).toHaveBeenCalledTimes(1);
    expect(String(vi.mocked(console.warn).mock.calls[0][0])).not.toContain("not-an-email");
  });

  it("retries a failure after 30 seconds", async () => {
    fetchMock.mockRejectedValueOnce(new TypeError("fetch failed"));
    fetchMock.mockResolvedValue(json({ supportEmail: "help@jobtrigger.app" }));
    let time = 0;
    const now = () => time;

    expect(await getAppInfo(now)).toBeNull();
    time = 31_000;
    expect(await getAppInfo(now)).toEqual({ supportEmail: "help@jobtrigger.app" });
  });
});
