import { describe, expect, it } from "vitest";

import { failureMessage } from "./app-failure";
import { maskSecret } from "./mask";

describe("maskSecret", () => {
  it("shows only the last four characters of a real-length secret", () => {
    expect(maskSecret("fake-secret-value-8899")).toBe("••••8899");
  });

  it("shows nothing of a short secret", () => {
    expect(maskSecret("abc123")).toBe("••••");
  });
});

describe("failureMessage", () => {
  // Verbatim from the app's AppFailure.message (app_failure.dart).
  it.each([
    [{ kind: "network" } as const, "Can't reach the server. Check your connection and try again."],
    [{ kind: "auth" } as const, "Your credentials were rejected. Please check them and try again."],
    [{ kind: "notFound" } as const, "That couldn't be found — it may have been removed."],
    [{ kind: "rejected", message: "Invalid credentials" } as const, "Invalid credentials"],
    [
      { kind: "server", status: 429 } as const,
      "Too many attempts. Please wait a few minutes and try again.",
    ],
    [
      { kind: "server", status: 500, requestId: "abc123" } as const,
      "Something went wrong on the server (HTTP 500). Reference: abc123",
    ],
    [{ kind: "server", status: 502 } as const, "Something went wrong on the server (HTTP 502)."],
    [{ kind: "unknown" } as const, "Something unexpected happened. Please try again."],
  ])("%o", (failure, copy) => {
    expect(failureMessage(failure)).toBe(copy);
  });
});
