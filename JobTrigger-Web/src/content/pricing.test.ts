import { describe, expect, it } from "vitest";

import { comparison, plans, pricingPromises } from "./pricing";

const row = (label: string) => {
  const found = comparison.find((r) => r.label === label);
  if (!found) throw new Error(`no row: ${label}`);
  return found;
};

describe("pricing content", () => {
  // Pinned: these are the entitlements matrix in
  // docs/subscription/02-business-model.md §3. A change is deliberate.
  it("has exactly the Free and Pro plans, in that order", () => {
    expect(plans.map((p) => p.id)).toEqual(["free", "pro"]);
  });

  it("states the agreed prices and trial", () => {
    const pro = plans[1];
    expect(pro.price).toBe("$3.99 / month");
    expect(pro.priceNote).toContain("$29.99 / year");
    expect(pro.priceNote).toContain("7-day free trial");
    expect(plans[0].price).toBe("$0");
  });

  it("matches the entitlements matrix row by row", () => {
    expect(row("Saved servers and accounts")).toEqual({
      label: "Saved servers and accounts",
      free: { included: true, note: "1" },
      pro: { included: true, note: "As many as you need" },
    });
    expect(row("CI tools at the same time").free).toEqual({ included: true, note: "One" });
    expect(row("Pinned jobs").free).toEqual({ included: true, note: "3" });
    for (const gated of [
      "Build notifications with the app closed",
      "Home-screen widget",
      "Build trends, nodes, queue and views",
    ]) {
      expect(row(gated).free).toEqual({ included: false });
      expect(row(gated).pro).toEqual({ included: true });
    }
  });

  it("never paywalls the core, the portal or security controls", () => {
    for (const label of [
      "Trigger, logs, history, stages and tests",
      "Set up servers on this website",
      "App lock, sign out everywhere, delete account",
    ]) {
      expect(row(label).free.included).toBe(true);
    }
  });

  it("every plan has highlights, and every row has a label", () => {
    for (const plan of plans) expect(plan.highlights.length).toBeGreaterThan(2);
    for (const r of comparison) expect(r.label).not.toBe("");
    expect(pricingPromises.length).toBeGreaterThan(0);
  });

  it("names no competitor and makes no unqualified superlative (§7.2)", () => {
    const text = JSON.stringify({ plans, comparison, pricingPromises }).toLowerCase();
    for (const banned of ["best ", "cheapest", "#1", "unlike ", "jenkinsview", "jenboard"]) {
      expect(text).not.toContain(banned);
    }
  });
});
