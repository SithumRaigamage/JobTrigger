import { afterEach, describe, expect, it } from "vitest";

import { cleanAnalyticsData } from "@/domain/analytics-events";

import { setAnalyticsSenderForTests, track } from "./analytics";
import { getAnalyticsConfig } from "./config";

const env = { UMAMI_URL: "http://localhost:3004/", UMAMI_WEBSITE_ID: "site-1" };

describe("getAnalyticsConfig (P20-77)", () => {
  it("is off unless both values are set and valid", () => {
    expect(getAnalyticsConfig({})).toBeNull();
    expect(getAnalyticsConfig({ UMAMI_URL: env.UMAMI_URL })).toBeNull();
    expect(getAnalyticsConfig({ ...env, UMAMI_URL: "not a url" })).toBeNull();
    expect(getAnalyticsConfig({ ...env, UMAMI_URL: "javascript:alert(1)" })).toBeNull();
    expect(getAnalyticsConfig(env)).toEqual({ url: "http://localhost:3004", websiteId: "site-1" });
  });
});

describe("track (P20-77)", () => {
  const saved = { ...process.env };
  afterEach(() => {
    process.env = { ...saved };
    setAnalyticsSenderForTests(null);
  });

  it("sends nothing when Umami isn't configured", async () => {
    delete process.env.UMAMI_URL;
    const sent: unknown[] = [];
    setAnalyticsSenderForTests(async (_url, body) => void sent.push(body));
    expect(await track("signup")).toBe(false);
    expect(sent).toEqual([]);
  });

  it("posts a Umami event with clean data", async () => {
    Object.assign(process.env, env);
    const sent: { url: string; body: unknown }[] = [];
    setAnalyticsSenderForTests(async (url, body) => void sent.push({ url, body }));

    expect(await track("server_added", { tool: "jenkins", url: "x".repeat(80) })).toBe(true);
    expect(sent).toEqual([
      {
        url: "http://localhost:3004/api/send",
        body: {
          type: "event",
          payload: {
            website: "site-1",
            hostname: "web.jobtrigger.local",
            url: "/",
            name: "server_added",
            data: { tool: "jenkins" },
          },
        },
      },
    ]);
  });

  it("never rejects when Umami fails", async () => {
    Object.assign(process.env, env);
    setAnalyticsSenderForTests(async () => {
      throw new Error("down");
    });
    await expect(track("signup")).resolves.toBe(false);
  });
});

describe("cleanAnalyticsData", () => {
  it("keeps short primitives under identifier keys", () => {
    expect(
      cleanAnalyticsData({ ok: "yes", n: 1, b: false, o: {}, "bad key": 1, long: "x".repeat(65) }),
    ).toEqual({ ok: "yes", n: 1, b: false });
    expect(cleanAnalyticsData({ "bad key": 1 })).toBeUndefined();
  });
});
