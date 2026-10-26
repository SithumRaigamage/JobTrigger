import { describe, expect, it, vi } from "vitest";

import { getSiteUrl, parseConfig } from "./config";

const secret = "s".repeat(32);

describe("parseConfig", () => {
  it("accepts a local http backend in development and trims trailing slashes", () => {
    const config = parseConfig({
      NODE_ENV: "development",
      JOBTRIGGER_BACKEND_URL: "http://127.0.0.1:5001/",
      SESSION_SECRET: secret,
    });

    expect(config).toEqual({
      backendUrl: "http://127.0.0.1:5001",
      sessionSecret: secret,
      siteUrl: "http://localhost:3000",
    });
  });

  it("requires https for the backend in production", () => {
    expect(() =>
      parseConfig({
        NODE_ENV: "production",
        JOBTRIGGER_BACKEND_URL: "http://api.example.com",
        SESSION_SECRET: secret,
      }),
    ).toThrow("JOBTRIGGER_BACKEND_URL: must be https:// in production");
  });

  it.each(["http://127.0.0.1:5001", "http://localhost:5001", "http://[::1]:5001"])(
    "allows plain http to a loopback backend in production: %s",
    (url) => {
      expect(
        parseConfig({ NODE_ENV: "production", JOBTRIGGER_BACKEND_URL: url, SESSION_SECRET: secret })
          .backendUrl,
      ).toBe(url);
    },
  );

  it("still rejects http to a private-network host in production", () => {
    expect(() =>
      parseConfig({
        NODE_ENV: "production",
        JOBTRIGGER_BACKEND_URL: "http://backend:5001",
        SESSION_SECRET: secret,
      }),
    ).toThrow("must be https:// in production");
  });

  it("accepts an https backend in production", () => {
    const config = parseConfig({
      NODE_ENV: "production",
      JOBTRIGGER_BACKEND_URL: "https://api.example.com",
      SESSION_SECRET: secret,
      SITE_URL: "https://jobtrigger.app",
    });

    expect(config.backendUrl).toBe("https://api.example.com");
    expect(config.siteUrl).toBe("https://jobtrigger.app");
  });

  it("lists every missing variable at once", () => {
    expect(() => parseConfig({})).toThrow(/JOBTRIGGER_BACKEND_URL.*SESSION_SECRET/);
  });

  it("rejects a short session secret without echoing it", () => {
    const short = "too-short-secret";
    let message = "";
    try {
      parseConfig({ JOBTRIGGER_BACKEND_URL: "http://127.0.0.1:5001", SESSION_SECRET: short });
    } catch (error) {
      message = (error as Error).message;
    }

    expect(message).toContain("SESSION_SECRET: must be at least 32 characters");
    expect(message).not.toContain(short);
  });
});

describe("getSiteUrl", () => {
  it("defaults to the local dev URL and needs no portal secrets", () => {
    expect(getSiteUrl({})).toBe("http://localhost:3000");
  });

  it("trims a trailing slash", () => {
    expect(getSiteUrl({ SITE_URL: "https://jobtrigger.app/" })).toBe("https://jobtrigger.app");
  });

  it("rejects a malformed URL", () => {
    expect(() => getSiteUrl({ SITE_URL: "not a url" })).toThrow("SITE_URL");
  });
});

describe("isPortalConfigured", () => {
  it("is false, without throwing, when the portal's variables are missing", async () => {
    vi.resetModules();
    vi.stubEnv("JOBTRIGGER_BACKEND_URL", "");
    vi.stubEnv("SESSION_SECRET", "");
    vi.spyOn(console, "warn").mockImplementation(() => {});
    const { isPortalConfigured } = await import("./config");

    expect(isPortalConfigured()).toBe(false);
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });
});
