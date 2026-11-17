import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { PaddleConfig } from "@/billing/paddle-config";
import type { Subscription } from "@/domain/subscription";

import { billingMode } from "./billing-mode";
import { BillingView } from "./billing-view";

// The client buttons load Paddle.js; their behaviour is covered end to end.
vi.mock("./billing-actions", () => ({
  UpgradeButtons: ({ clientToken, environment }: { clientToken: string; environment: string }) => (
    <div data-testid="upgrade">{`${environment}:${clientToken}`}</div>
  ),
  ManageButton: () => <button type="button">Manage subscription</button>,
}));

const paddle: PaddleConfig = { clientToken: "test_0123456789abcdefghij", environment: "sandbox" };

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
const pro = (source: Subscription["source"]): Subscription => ({
  ...free,
  plan: "pro",
  state: "active",
  source,
  willRenew: true,
  periodEnd: "2027-03-03T10:00:00.000Z",
});

describe("billingMode", () => {
  it.each([
    ["no plan", null, paddle, "unavailable"],
    ["billing off", { ...free, billingEnabled: false }, paddle, "unavailable"],
    ["Paddle not set up", free, null, "unavailable"],
    ["Free", free, paddle, "upgrade"],
    ["Pro from the website", pro("web"), paddle, "manage"],
    ["Pro from the App Store", pro("appStore"), paddle, "store"],
    ["Pro from Google Play", pro("playStore"), paddle, "store"],
    ["Pro by promotion", pro("promo"), paddle, "other"],
  ] as const)("%s → %s", (_name, subscription, config, mode) => {
    expect(billingMode(subscription, config)).toBe(mode);
  });
});

describe("BillingView", () => {
  it("offers the upgrade with Paddle named as the seller", () => {
    render(<BillingView subscription={free} paddle={paddle} />);

    expect(screen.getByRole("heading", { level: 1, name: "Billing" })).toBeVisible();
    expect(screen.getByTestId("upgrade")).toHaveTextContent("sandbox:test_0123456789abcdefghij");
    expect(screen.getByText("Paddle")).toBeVisible();
    expect(screen.getByRole("link", { name: "terms" })).toHaveAttribute("href", "/terms");
  });

  it("offers the portal for a website subscription", () => {
    render(<BillingView subscription={pro("web")} paddle={paddle} />);
    expect(screen.getByRole("button", { name: "Manage subscription" })).toBeVisible();
    expect(screen.queryByTestId("upgrade")).not.toBeInTheDocument();
  });

  it("explains a store subscription and sells nothing on top of it", () => {
    render(<BillingView subscription={pro("appStore")} paddle={paddle} />);
    expect(screen.getByText(/managed by the store you bought it in/)).toBeVisible();
    expect(screen.queryByTestId("upgrade")).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /manage/i })).not.toBeInTheDocument();
  });

  it("says buying isn't available when billing is off or Paddle isn't set up", () => {
    const { rerender } = render(<BillingView subscription={null} paddle={paddle} />);
    expect(screen.getByText(/Buying on the website isn't available right now/)).toBeVisible();
    rerender(<BillingView subscription={free} paddle={null} />);
    expect(screen.getByText(/Buying on the website isn't available right now/)).toBeVisible();
    expect(screen.queryByTestId("upgrade")).not.toBeInTheDocument();
  });
});
