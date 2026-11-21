/*
 * US-SUB-11 (release 1.1): the team plan, as the website shows it.
 * docs/user-stories/billing/18-subscriptions.md, AC12–AC15.
 */

export type TeamRole = "owner" | "member";

export type TeamMember = { userId: string; email: string | null; owner: boolean; joinedAt: string };

export type TeamInvite = { id: string; email: string; expiresAt: string };

export type TeamPrices = { monthly: number; yearly: number; minSeats: number; maxSeats: number };

export type Team = {
  id: string;
  name: string;
  role: TeamRole;
  seats: number;
  seatsUsed: number;
  active: boolean;
  billing: {
    status: string;
    period: "monthly" | "yearly" | null;
    periodEnd: string | null;
    willRenew: boolean;
  };
  members: TeamMember[];
  invites: TeamInvite[];
  sharedServerIds: string[];
  prices: TeamPrices;
};

/** The team page's three states: off on this backend, no team yet, a team. */
export type TeamState = { available: false } | { available: true; team: Team | null };

export type TeamPeriod = "monthly" | "yearly";

/** The published per-seat prices (the backend's Paddle prices carry the real amounts). */
export const TEAM_PRICES: TeamPrices = { monthly: 6.99, yearly: 69.9, minSeats: 2, maxSeats: 100 };

/** AC13: the total for [seats] at [period], in USD, rounded to cents. */
export function teamTotal(prices: TeamPrices, seats: number, period: TeamPeriod): number {
  return Math.round(prices[period] * seats * 100) / 100;
}

/** "$13.98" */
export function usd(amount: number): string {
  return `$${amount.toFixed(2)}`;
}
