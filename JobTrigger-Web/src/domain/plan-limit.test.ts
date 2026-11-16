import { describe, expect, it } from "vitest";

import { failureMessage } from "./app-failure";

describe("plan-limit failure copy (P20-31)", () => {
  it("tells a Free user where to upgrade, without a link to buy", () => {
    const text = failureMessage({ kind: "planLimit", limit: "maxCredentialsTotal" });
    expect(text).toBe(
      "Your plan's limit has been reached. Upgrade in the JobTrigger app to add more.",
    );
    expect(text).not.toMatch(/https?:|checkout|buy/i);
  });

  it("says a locked server is locked", () => {
    expect(failureMessage({ kind: "planLimit", limit: "locked" })).toBe(
      "This server is locked on your plan. Upgrade in the JobTrigger app to use it.",
    );
  });

  it("uses the general wording for any other limit", () => {
    expect(failureMessage({ kind: "planLimit", limit: "multiTool" })).toContain(
      "Upgrade in the JobTrigger app",
    );
  });
});
