import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { Subscription } from "@/domain/subscription";

import { AccountView } from "./account-view";
import { deleteNotice, manageInstructions, planDate, planSummary } from "./plan-section";

const free: Subscription = {
  plan: "free",
  billingEnabled: true,
  state: "none",
  source: null,
  periodEnd: null,
  willRenew: false,
  manageOnWeb: false,
  limits: { maxCredentialsTotal: 1, maxCredentialsPerTool: 1, maxPinnedJobs: 3 },
  features: { multiTool: false, backgroundWatch: false, homeWidget: false, insights: false },
};

const pro: Subscription = {
  ...free,
  plan: "pro",
  state: "active",
  source: "appStore",
  periodEnd: "2027-03-03T10:00:00.000Z",
  willRenew: true,
  limits: { maxCredentialsTotal: null, maxCredentialsPerTool: 25, maxPinnedJobs: null },
  features: { multiTool: true, backgroundWatch: true, homeWidget: true, insights: true },
};

describe("plan text", () => {
  it("formats dates and ignores bad ones", () => {
    expect(planDate("2027-03-03T10:00:00.000Z")).toBe("March 3, 2027");
    expect(planDate(null)).toBeNull();
    expect(planDate("not a date")).toBeNull();
  });

  it.each([
    [free, "You're on the Free plan."],
    [{ ...free, state: "expired" as const }, "Your Pro plan has ended. You're on the Free plan."],
    [pro, "You're on Pro through the App Store. It renews on March 3, 2027."],
    [
      { ...pro, state: "trialing" as const },
      "You're on Pro through the App Store, in your free trial until March 3, 2027.",
    ],
    [
      { ...pro, state: "cancelled" as const, willRenew: false },
      "You're on Pro through the App Store. It won't renew and ends on March 3, 2027.",
    ],
    [
      { ...pro, source: "web" as const, state: "billingIssue" as const },
      "You're on Pro through the JobTrigger website, but the last payment didn't go through. Pro continues until March 3, 2027 unless it is fixed.",
    ],
  ])("summary %#", (subscription, text) => {
    expect(planSummary(subscription)).toBe(text);
  });

  it("says where to manage it, per source, and never links to buy", () => {
    expect(manageInstructions(pro)).toContain("iPhone's Settings");
    expect(manageInstructions({ ...pro, source: "playStore" })).toContain("Google Play");
    expect(manageInstructions({ ...pro, source: "web" })).toContain("this website");
    expect(manageInstructions(free)).toBeNull();
    expect(manageInstructions({ ...pro, source: "promo" })).toBeNull();
  });

  it("warns that deleting the account doesn't cancel a paid subscription", () => {
    expect(deleteNotice(pro)).toContain("does not cancel your App Store subscription");
    expect(deleteNotice({ ...pro, source: "playStore" })).toContain("Google Play");
    expect(deleteNotice(free)).toBeNull();
    expect(deleteNotice({ ...pro, source: "admin" })).toBeNull();
  });
});

describe("AccountView plan section", () => {
  it("shows the plan, limits and the manage instructions for Pro", () => {
    render(<AccountView email="sam@acme.dev" subscription={pro} />);

    const region = screen.getByRole("region", { name: "Plan" });
    expect(region).toHaveTextContent("You're on Pro through the App Store");
    expect(region).toHaveTextContent("Unlimited saved servers in total");
    expect(region).toHaveTextContent("All tools together");
    expect(region).toHaveTextContent("Manage or cancel it in your iPhone's Settings");
    expect(screen.getByText(/does not cancel your App Store subscription/)).toBeVisible();
  });

  it("shows Free with its limits and says Pro is bought in the app", () => {
    render(<AccountView email="sam@acme.dev" subscription={free} />);

    const region = screen.getByRole("region", { name: "Plan" });
    expect(region).toHaveTextContent("You're on the Free plan.");
    expect(region).toHaveTextContent("1 saved servers in total");
    expect(region).toHaveTextContent("Pro is bought in the JobTrigger app.");
    expect(screen.queryByRole("link", { name: /buy|checkout|upgrade/i })).not.toBeInTheDocument();
  });

  it("has no plan section when billing is off or the plan couldn't be read", () => {
    render(<AccountView email="sam@acme.dev" subscription={null} />);
    expect(screen.queryByRole("region", { name: "Plan" })).not.toBeInTheDocument();
    expect(screen.queryByText(/does not cancel/)).not.toBeInTheDocument();
  });
});
