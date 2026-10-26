import { describe, expect, it } from "vitest";

import { isValidEmail, newPasswordProblem } from "@/domain/auth-validation";

import { safeNext } from "./safe-next";

describe("safeNext", () => {
  it.each(["/servers", "/servers/new", "/servers/abc/edit?x=1", "/account"])("keeps %s", (next) => {
    expect(safeNext(next)).toBe(next);
  });

  it.each([
    "https://evil.example/",
    "//evil.example/servers",
    "/\\evil.example",
    "/features",
    "/sign-in",
    "servers",
    "",
    null,
  ])("falls back to /servers for %s", (next) => {
    expect(safeNext(next)).toBe("/servers");
  });
});

describe("auth validation (same rules as the app and backend)", () => {
  it("accepts and rejects emails like AuthValidation.isValidEmail", () => {
    expect(isValidEmail(" sam@acme.dev ")).toBe(true);
    expect(isValidEmail("sam@acme")).toBe(false);
    expect(isValidEmail("sam acme@x.io")).toBe(false);
  });

  it("uses the backend's password copy", () => {
    expect(newPasswordProblem("1234567")).toBe("Password must be at least 8 characters long");
    expect(newPasswordProblem("12345678")).toBeNull();
    expect(newPasswordProblem("é".repeat(37))).toBe("Password is too long"); // 74 bytes
  });
});
