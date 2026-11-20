import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { PaddleConfig } from "@/billing/paddle-config";
import type { Team } from "@/domain/team";
import { TEAM_PRICES } from "@/domain/team";

// US-SUB-11 AC13: the billing page's team section, and the real
// TeamCheckout's price maths. Paddle.js itself isn't loaded in tests.
vi.mock("next/script", () => ({ default: () => null }));
vi.mock("@/features/team/actions", () => ({ startTeamCheckoutAction: vi.fn() }));
vi.mock("./actions", () => ({ openPortalAction: vi.fn(), startCheckoutAction: vi.fn() }));

import { TeamCheckout } from "./billing-actions";
import { BillingView } from "./billing-view";

const paddle: PaddleConfig = { clientToken: "test-client-token", environment: "sandbox" };
const team: Team = {
  id: "t1",
  name: "Platform",
  role: "owner",
  seats: 2,
  seatsUsed: 3,
  active: false,
  billing: { status: "none", period: null, periodEnd: null, willRenew: false },
  members: [],
  invites: [],
  sharedServerIds: [],
  prices: TEAM_PRICES,
};

describe("BillingView team section", () => {
  it("an owner without a subscription can buy seats, at least the ones in use", () => {
    render(<BillingView subscription={null} paddle={paddle} team={team} />);
    expect(screen.getByRole("heading", { name: "Team: Platform" })).toBeVisible();
    expect(screen.getByText(/you need at least 3/)).toBeVisible();
    expect(screen.getByTestId("team-checkout")).toBeVisible();
  });

  it("a subscribed team changes seats on the team page instead", () => {
    const paid = {
      ...team,
      active: true,
      billing: { ...team.billing, status: "active", willRenew: true },
    };
    render(<BillingView subscription={null} paddle={paddle} team={paid} />);
    expect(screen.getByTestId("team-billing-subscribed")).toHaveTextContent("2 seats");
    expect(screen.queryByTestId("team-checkout")).not.toBeInTheDocument();
  });

  it("a member, or no team, sees no team section", () => {
    const { rerender } = render(
      <BillingView subscription={null} paddle={paddle} team={{ ...team, role: "member" }} />,
    );
    expect(screen.queryByText(/Team:/)).not.toBeInTheDocument();
    rerender(<BillingView subscription={null} paddle={paddle} team={null} />);
    expect(screen.queryByText(/Team:/)).not.toBeInTheDocument();
  });

  it("without Paddle it says buying isn't available", () => {
    render(<BillingView subscription={null} paddle={null} team={team} />);
    expect(screen.getByText(/Buying for a team on the website isn't available/)).toBeVisible();
  });
});

describe("TeamCheckout", () => {
  it("shows the total for the seats and period, and refuses too few seats", () => {
    render(
      <TeamCheckout clientToken="t" environment="sandbox" prices={TEAM_PRICES} minSeats={3} />,
    );
    expect(screen.getByTestId("team-total")).toHaveTextContent(
      "3 seats × $69.90 = $209.70 per year",
    );
    fireEvent.click(screen.getByLabelText("Monthly"));
    expect(screen.getByTestId("team-total")).toHaveTextContent(
      "3 seats × $6.99 = $20.97 per month",
    );
    fireEvent.change(screen.getByLabelText("Seats"), { target: { value: "2" } });
    expect(screen.getByTestId("team-total")).toHaveTextContent("Choose 3 to 100 seats.");
    expect(screen.getByRole("button", { name: "Buy Pro for the team" })).toBeDisabled();
  });
});
