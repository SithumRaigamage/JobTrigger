import { describe, expect, it } from "vitest";

import {
  contentSecurityPolicy,
  createNonce,
  isNoStorePath,
  staticSecurityHeaders,
} from "./security-headers";

describe("contentSecurityPolicy", () => {
  const production = contentSecurityPolicy("abc123", false);

  it("allows scripts and styles only from this site or with the nonce", () => {
    expect(production).toContain("script-src 'self' 'nonce-abc123' 'strict-dynamic'");
    expect(production).toContain("style-src 'self' 'nonce-abc123'");
    expect(production).not.toContain("unsafe-inline");
    expect(production).not.toContain("unsafe-eval");
  });

  it("forbids framing, plugins, base-tag and off-site form hijacking", () => {
    for (const directive of [
      "frame-ancestors 'none'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "default-src 'self'",
    ]) {
      expect(production).toContain(directive);
    }
  });

  it("upgrades insecure requests in production only", () => {
    expect(production).toContain("upgrade-insecure-requests");
    expect(contentSecurityPolicy("abc123", true)).not.toContain("upgrade-insecure-requests");
  });

  it("adds 'unsafe-eval' only in development", () => {
    expect(contentSecurityPolicy("abc123", true)).toContain("'unsafe-eval'");
  });
});

describe("contentSecurityPolicy reporting host (E3)", () => {
  it("allows connecting to the crash-report host only when one is configured", () => {
    expect(contentSecurityPolicy("n", false)).toContain("connect-src 'self';");
    expect(contentSecurityPolicy("n", false, "https://glitch.example.com")).toContain(
      "connect-src 'self' https://glitch.example.com;",
    );
  });
});

describe("createNonce", () => {
  it("is different every time", () => {
    const nonces = new Set(Array.from({ length: 50 }, createNonce));
    expect(nonces.size).toBe(50);
  });
});

describe("isNoStorePath", () => {
  it.each(["/servers", "/servers/new", "/account", "/sign-in", "/sign-up"])("%s", (path) => {
    expect(isNoStorePath(path)).toBe(true);
  });

  it.each(["/", "/features", "/serversxyz", "/security"])("not %s", (path) => {
    expect(isNoStorePath(path)).toBe(false);
  });
});

describe("staticSecurityHeaders", () => {
  it("sets HSTS without preload, nosniff and DENY framing", () => {
    const headers = Object.fromEntries(staticSecurityHeaders().map((h) => [h.key, h.value]));

    expect(headers["Strict-Transport-Security"]).toBe("max-age=63072000; includeSubDomains");
    expect(headers["X-Content-Type-Options"]).toBe("nosniff");
    expect(headers["X-Frame-Options"]).toBe("DENY");
  });
});

describe("contentSecurityPolicy on the billing page (P20-83)", () => {
  const strict = contentSecurityPolicy("n", false);
  const sandbox = contentSecurityPolicy("n", false, null, { environment: "sandbox" });
  const production = contentSecurityPolicy("n", false, null, { environment: "production" });

  it("is unchanged for every page that isn't the billing page", () => {
    expect(strict).not.toContain("paddle");
    expect(strict).not.toContain("frame-src");
    expect(contentSecurityPolicy("n", false, null, null)).toBe(strict);
  });

  it("allows Paddle.js, its API and its checkout frame, for the environment in use only", () => {
    expect(sandbox).toContain(
      "script-src 'self' 'nonce-n' 'strict-dynamic' https://cdn.paddle.com",
    );
    expect(sandbox).toContain("connect-src 'self' https://sandbox-checkout-service.paddle.com;");
    expect(sandbox).toContain("frame-src https://sandbox-buy.paddle.com;");
    expect(sandbox).not.toContain("https://checkout-service.paddle.com");

    expect(production).toContain("connect-src 'self' https://checkout-service.paddle.com;");
    expect(production).toContain("frame-src https://buy.paddle.com;");
    expect(production).not.toContain("sandbox");
  });

  it("loosens nothing else", () => {
    for (const policy of [sandbox, production]) {
      expect(policy).not.toContain("unsafe-inline");
      expect(policy).not.toContain("unsafe-eval");
      expect(policy).toContain("style-src 'self' 'nonce-n'");
      expect(policy).toContain("default-src 'self'");
      expect(policy).toContain("frame-ancestors 'none'");
      expect(policy).toContain("form-action 'self'");
      expect(policy).toContain("object-src 'none'");
    }
  });

  it("keeps the crash-report host alongside Paddle", () => {
    expect(
      contentSecurityPolicy("n", false, "https://glitch.example.com", { environment: "sandbox" }),
    ).toContain(
      "connect-src 'self' https://glitch.example.com https://sandbox-checkout-service.paddle.com;",
    );
  });
});
