import { describe, expect, it } from "vitest";

import { BILLING_PATH, getPaddleConfig, isBillingPath, PADDLE_SCRIPT_URL } from "./paddle-config";

const sandbox = "test_0123456789abcdefghij";
const live = "live_0123456789abcdefghij";

describe("getPaddleConfig", () => {
  it("is off without a client token", () => {
    expect(getPaddleConfig({})).toBeNull();
    expect(getPaddleConfig({ PADDLE_CLIENT_TOKEN: "  " })).toBeNull();
  });

  it("reads a sandbox token, and sandbox is the default environment", () => {
    expect(getPaddleConfig({ PADDLE_CLIENT_TOKEN: sandbox })).toEqual({
      clientToken: sandbox,
      environment: "sandbox",
    });
  });

  it("reads a live token only with PADDLE_ENV=production", () => {
    expect(getPaddleConfig({ PADDLE_CLIENT_TOKEN: live, PADDLE_ENV: "production" })).toEqual({
      clientToken: live,
      environment: "production",
    });
  });

  it("turns checkout off when the token and environment disagree", () => {
    expect(getPaddleConfig({ PADDLE_CLIENT_TOKEN: live })).toBeNull();
    expect(getPaddleConfig({ PADDLE_CLIENT_TOKEN: sandbox, PADDLE_ENV: "production" })).toBeNull();
  });

  it("rejects a value that is not a Paddle client token", () => {
    expect(getPaddleConfig({ PADDLE_CLIENT_TOKEN: "pdl_live_apikey_01hxyz" })).toBeNull();
    expect(getPaddleConfig({ PADDLE_CLIENT_TOKEN: "test_short" })).toBeNull();
  });
});

describe("billing page constants", () => {
  it("loads Paddle.js from Paddle's official CDN over https", () => {
    expect(PADDLE_SCRIPT_URL).toBe("https://cdn.paddle.com/paddle/v2/paddle.js");
  });

  it("knows only the billing page", () => {
    expect(isBillingPath(BILLING_PATH)).toBe(true);
    expect(isBillingPath("/account/billing/")).toBe(true);
    for (const other of ["/account", "/account/billing/x", "/billing", "/servers", "/pricing"]) {
      expect(isBillingPath(other)).toBe(false);
    }
  });
});
