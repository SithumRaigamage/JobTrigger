import { describe, expect, it } from "vitest";

import { reportingConfig, reportingOrigin } from "./config";
import { scrubEvent, scrubString, scrubUrl } from "./scrub";

// Assembled at runtime so no token-shaped literal sits in the tree (AUD-66).
const TOKEN = ["a1b2c3d4", "e5f60718", "2a3b4c5d", "6e7f8091"].join("");
const BASIC = Buffer.from(`user:${TOKEN}`).toString("base64");

const dirty = () => ({
  message: `failed with token ${TOKEN}`,
  exception: { values: [{ type: "Error", value: `Basic ${BASIC} rejected` }] },
  request: {
    method: "POST",
    url: `https://user:${TOKEN}@portal.example.com/servers/new?token=${TOKEN}#x`,
    query_string: `token=${TOKEN}`,
    data: { token: TOKEN },
    cookies: { jt_session: TOKEN },
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      "x-auth-token": TOKEN,
      Cookie: `jt_session=${TOKEN}`,
      "Set-Cookie": `jt_session=${TOKEN}`,
      "PRIVATE-TOKEN": TOKEN,
      "X-Api-Key": "k",
      "user-agent": "vitest",
    },
  },
  user: { id: 7, email: "someone@example.com", ip_address: "1.2.3.4" },
  breadcrumbs: [{ message: `typed ${TOKEN}` }],
  extra: { uri: `mongodb+srv://admin:${TOKEN}@cluster.example.net/db`, secret: TOKEN },
});

describe("scrubEvent", () => {
  it("removes the token from the message, headers and URL", () => {
    const clean = scrubEvent(dirty())!;
    const text = JSON.stringify(clean);
    expect(text).not.toContain(TOKEN);
    expect(text).not.toContain(BASIC);
    expect(clean.request!.url).toBe("https://portal.example.com/servers/new");
    expect(clean.request!.headers).toEqual({ "user-agent": "vitest" });
    expect(clean.request).not.toHaveProperty("data");
    expect(clean.request).not.toHaveProperty("cookies");
    expect(clean.request).not.toHaveProperty("query_string");
  });

  it("keeps no email, address, breadcrumbs or database password", () => {
    const clean = scrubEvent(dirty())!;
    const text = JSON.stringify(clean);
    expect(text).not.toContain("someone@example.com");
    expect(text).not.toContain("1.2.3.4");
    expect(text).not.toContain("admin:");
    expect(clean.user).toEqual({ id: "7" });
    expect(clean).not.toHaveProperty("breadcrumbs");
  });

  it("drops the event when it cannot be scrubbed", () => {
    const broken = {};
    Object.defineProperty(broken, "message", {
      enumerable: true,
      get() {
        throw new Error("boom");
      },
    });
    expect(scrubEvent(broken)).toBeNull();
  });
});

describe("scrubString and scrubUrl", () => {
  it("redacts key/value secrets but leaves ordinary text", () => {
    expect(scrubString("password=hunter2 for host a")).toBe("password=[redacted] for host a");
    expect(scrubString("server down at https://j.example.com/x?y=1")).toBe(
      "server down at https://j.example.com/x",
    );
  });

  it("strips query, fragment and credentials from a URL", () => {
    expect(scrubUrl("https://a:b@h.example.com/p?q=1#f")).toBe("https://h.example.com/p");
  });
});

describe("reportingConfig", () => {
  it("is off without a DSN", () => {
    expect(reportingConfig({})).toBeNull();
    expect(reportingConfig({ NEXT_PUBLIC_SENTRY_DSN: " " })).toBeNull();
  });

  it("names the environment and release", () => {
    const dev = reportingConfig({ NEXT_PUBLIC_SENTRY_DSN: "https://k@h.example.com/1" })!;
    expect(dev.environment).toBe("development");
    expect(dev.release).toMatch(/^\d+\.\d+\.\d+/);
    const prod = reportingConfig({
      NEXT_PUBLIC_SENTRY_DSN: "https://k@h.example.com/1",
      NODE_ENV: "production",
      NEXT_PUBLIC_SENTRY_RELEASE: "web@1.0.0+3",
    })!;
    expect(prod).toMatchObject({ environment: "production", release: "web@1.0.0+3" });
  });

  it("gives the origin for the CSP", () => {
    expect(reportingOrigin("https://k@glitch.example.com:3005/2")).toBe(
      "https://glitch.example.com:3005",
    );
    expect(reportingOrigin(undefined)).toBeNull();
    expect(reportingOrigin("nonsense")).toBeNull();
  });
});
