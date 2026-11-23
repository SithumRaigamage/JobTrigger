import { describe, expect, it } from "vitest";

import {
  AREA_LABELS,
  CATEGORY_LABELS,
  IMPACT_LABELS,
  STATUS_LABELS,
  checkScreenshotMeta,
  labelFor,
  looksLikeScreenshot,
  screenshotProblemMessage,
} from "./support";

describe("support option labels (US-SUP-05)", () => {
  it("covers the seven categories and the wire values stay the old ones", () => {
    expect(Object.keys(CATEGORY_LABELS)).toEqual([
      "bug",
      "feature",
      "question",
      "tool_request",
      "account",
      "billing",
      "other",
    ]);
    expect(CATEGORY_LABELS.tool_request).toBe("Tool request");
    expect(CATEGORY_LABELS.billing).toBe("Billing & subscription");
  });

  it("an unknown wire value from an older ticket still reads", () => {
    expect(labelFor(CATEGORY_LABELS, "retired_kind")).toBe("retired_kind");
    expect(labelFor(AREA_LABELS, "github")).toBe("GitHub Actions");
    expect(labelFor(IMPACT_LABELS, "blocked")).toBe("Blocked");
    expect(labelFor(STATUS_LABELS, "triaged")).toBe("Triaged");
  });
});

describe("screenshot checks (US-SUP-06)", () => {
  const png = Uint8Array.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2]);
  const jpg = Uint8Array.from([0xff, 0xd8, 0xff, 0xe0, 1, 2]);

  it("checks the name and size cheaply, then the leading bytes", () => {
    expect(checkScreenshotMeta("shot.PNG", 200)).toBeNull();
    expect(checkScreenshotMeta("shot.jpg", 200)).toBeNull();
    expect(checkScreenshotMeta("empty.png", 0)).toBe("empty");
    expect(checkScreenshotMeta("huge.png", 5 * 1024 * 1024 + 1)).toBe("tooLarge");
    expect(checkScreenshotMeta("notes.pdf", 200)).toBe("wrongType");
    expect(looksLikeScreenshot(png)).toBe(true);
    expect(looksLikeScreenshot(jpg)).toBe(true);
    // A text file renamed .png is refused despite its honest extension.
    expect(looksLikeScreenshot(Uint8Array.from([0x48, 0x69, 0x21, 1, 2]))).toBe(false);
  });

  it("names the reason in the form's own words", () => {
    expect(screenshotProblemMessage("empty")).toMatch(/empty/i);
    expect(screenshotProblemMessage("tooLarge")).toContain("5 MB");
    expect(screenshotProblemMessage("wrongType")).toContain("JPG or PNG");
  });
});
