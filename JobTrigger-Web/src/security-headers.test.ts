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
