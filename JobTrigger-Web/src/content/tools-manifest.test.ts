// @vitest-environment node
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

// The repo's one release manifest and this project's copy of it must be
// identical (scripts/sync-tools.mjs). A failure means someone edited one
// without running `node scripts/sync-tools.mjs`.
const source = resolve(process.cwd(), "..", "release", "tools.json");
const copy = resolve(process.cwd(), "src", "content", "tools.json");

describe("release manifest copy", () => {
  // The monorepo checkout has the source; a standalone deploy of this folder doesn't.
  it.skipIf(!existsSync(source))("is byte-identical to release/tools.json", () => {
    expect(readFileSync(copy, "utf8")).toBe(readFileSync(source, "utf8"));
  });
});
