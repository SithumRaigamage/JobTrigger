import { describe, expect, it } from "vitest";

import { parseConfig } from "./config";

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
