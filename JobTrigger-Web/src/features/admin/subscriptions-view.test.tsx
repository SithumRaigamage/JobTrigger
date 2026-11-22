import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminPromoCode, AdminSubscription } from "@/domain/admin-subscription";

// The grant/revoke forms are client components with server actions; the
// console's own copy and numbers are what this file checks.
vi.mock("./subscription-forms", () => ({
  PlanAdminForms: () => <div data-testid="plan-forms" />,
}));

import { promoCodeLine, SubscriptionsView } from "./subscriptions-view";

const account: AdminSubscription = {
  userId: "64b0000000000000000000aa",
  email: "kasun@example.com",
  plan: "free",
  state: "none",
  source: null,
  periodEnd: null,
  willRenew: false,
  sources: { store: null, web: null, grant: null, student: null, promo: null },
  createdAt: "2026-11-18T00:00:00.000Z",
};

const capped: AdminPromoCode = {
  code: "LAUNCH30",
  kind: "pro",
  days: 30,
  redemptions: 3,
  maxRedemptions: 50,
  remaining: 47,
  expiresAt: null,
  expired: false,
};

const open: AdminPromoCode = {
  code: "OPEN7",
  kind: "pro",
  days: 7,
  redemptions: 4,
  maxRedemptions: null,
  remaining: null,
  expiresAt: null,
  expired: false,
};

const checkout: AdminPromoCode = {
  code: "SAVE20",
  kind: "checkout",
  days: null,
  redemptions: null,
  maxRedemptions: null,
  remaining: null,
  // Midday UTC, so the local date is the same on every test machine.
  expiresAt: "2027-01-31T12:00:00.000Z",
  expired: false,
};

describe("promoCodeLine (US-PROMO-05)", () => {
  it("says the days, the redemptions and what is left of the cap", () => {
    expect(promoCodeLine(capped)).toBe("Pro for 30 days · 3 redeemed of 50, 47 left");
    expect(promoCodeLine(open)).toBe("Pro for 7 days · 4 redeemed");
  });

  it("says a checkout discount is counted by Paddle, and shows a retired code", () => {
    expect(promoCodeLine(checkout)).toBe(
      "money off the website checkout (Paddle counts its redemptions) · usable until January 31, 2027",
    );
    expect(promoCodeLine({ ...capped, expired: true })).toBe(
      "Pro for 30 days · 3 redeemed of 50, 47 left · past its last day",
    );
  });
});

describe("SubscriptionsView promo codes", () => {
  it("lists every configured code with its usage", () => {
    render(
      <SubscriptionsView
        items={[account]}
        codes={[capped, open, checkout]}
        failure={null}
        plan="all"
        q=""
      />,
    );

    expect(screen.getByRole("heading", { name: "Promo codes" })).toBeVisible();
    expect(screen.getByText("LAUNCH30")).toBeVisible();
    expect(screen.getByText("Pro for 30 days · 3 redeemed of 50, 47 left")).toBeVisible();
    expect(screen.getByText("Pro for 7 days · 4 redeemed")).toBeVisible();
    expect(screen.getByText(/Paddle counts its redemptions/)).toBeVisible();
    // The accounts list is still there underneath.
    expect(screen.getByText("kasun@example.com")).toBeVisible();
  });

  it("shows no code card when nothing is configured", () => {
    render(<SubscriptionsView items={[account]} codes={[]} failure={null} plan="all" q="" />);
    expect(screen.queryByRole("heading", { name: "Promo codes" })).not.toBeInTheDocument();
  });

  it("still names the code an account redeemed", () => {
    render(
      <SubscriptionsView
        items={[
          {
            ...account,
            plan: "pro",
            state: "active",
            source: "promo",
            sources: {
              ...account.sources,
              promo: {
                plan: "pro",
                state: "active",
                source: "promo",
                productId: "LAUNCH30",
                periodEnd: "2027-01-15T00:00:00.000Z",
                willRenew: false,
              },
            },
          },
        ]}
        codes={[capped]}
        failure={null}
        plan="all"
        q=""
      />,
    );
    expect(screen.getByText(/Promo code LAUNCH30 until January 15, 2027/)).toBeVisible();
  });
});
