import { fireEvent, render, screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { Team } from "@/domain/team";
import { teamTotal, TEAM_PRICES, usd } from "@/domain/team";

import { JoinView } from "./join-view";
import { TeamView } from "./team-view";

// US-SUB-11 AC12 (team page) and AC14 (join page). The actions are server
// code, covered in actions.test.ts.
vi.mock("./actions", () => {
  const noop = async () => ({});
  return {
    createTeamAction: noop,
    inviteAction: noop,
    cancelInviteAction: noop,
    removeMemberAction: noop,
    leaveTeamAction: noop,
    deleteTeamAction: noop,
    setSeatsAction: noop,
    shareServerAction: noop,
    unshareServerAction: noop,
    joinTeamAction: noop,
  };
});

const owner: Team = {
  id: "t1",
  name: "Platform",
  role: "owner",
  seats: 3,
  seatsUsed: 3,
  active: true,
  billing: {
    status: "active",
    period: "yearly",
    periodEnd: "2027-01-01T00:00:00.000Z",
    willRenew: true,
  },
  members: [
    { userId: "u1", email: "owner@example.com", owner: true, joinedAt: "2026-11-20T00:00:00.000Z" },
    { userId: "u2", email: "dev@example.com", owner: false, joinedAt: "2026-11-20T00:00:00.000Z" },
  ],
  invites: [{ id: "i1", email: "new@example.com", expiresAt: "2026-11-27T00:00:00.000Z" }],
  sharedServerIds: ["c1"],
  prices: TEAM_PRICES,
};
const servers = [
  { id: "c1", serverName: "prod-ci", jenkinsURL: "https://ci.example.com" },
  { id: "c2", serverName: "lab", jenkinsURL: "https://lab.example.com" },
];

describe("TeamView (AC12)", () => {
  it("says teams aren't available when the backend has them off", () => {
    render(<TeamView state={{ available: false }} servers={[]} />);
    expect(screen.getByTestId("team-unavailable")).toHaveTextContent("coming in JobTrigger 1.1");
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  it("offers to create a team, with the price", () => {
    render(<TeamView state={{ available: true, team: null }} servers={[]} />);
    expect(screen.getByText(/\$6\.99 per seat per month, from 2 seats/)).toBeVisible();
    expect(screen.getByLabelText("Team name")).toBeRequired();
    expect(screen.getByRole("button", { name: "Create team" })).toBeVisible();
  });

  it("owner: seats, members, invites, sharing, and no invite form when full", () => {
    render(<TeamView state={{ available: true, team: owner }} servers={servers} />);
    expect(screen.getByTestId("team-seats")).toHaveTextContent("3 of 3 used");
    expect(screen.getByTestId("team-plan")).toHaveTextContent(
      "Pro for everyone in the team, renews",
    );

    const members = within(screen.getByTestId("team-members"));
    expect(members.getByText("owner@example.com")).toBeVisible();
    // Only non-owners can be removed; the invite can be cancelled.
    expect(members.getAllByRole("button", { name: "Remove" })).toHaveLength(1);
    expect(members.getByRole("button", { name: "Cancel invite" })).toBeVisible();
    expect(screen.queryByLabelText("Invite by email")).not.toBeInTheDocument();
    expect(screen.getByText(/Every seat is taken/)).toBeVisible();

    const shared = within(screen.getByTestId("team-servers"));
    expect(shared.getByText("prod-ci").closest("li")).toHaveTextContent("Stop sharing");
    expect(shared.getByText("lab").closest("li")).toHaveTextContent("Share");
    expect(screen.getByRole("button", { name: "Delete team" })).toBeVisible();
  });

  it("owner with a free seat can invite; an unpaid team links to billing", () => {
    const unpaid = { ...owner, seatsUsed: 2, active: false };
    render(<TeamView state={{ available: true, team: unpaid }} servers={[]} />);
    expect(screen.getByLabelText("Invite by email")).toHaveAttribute("type", "email");
    expect(screen.getByRole("link", { name: "Buy Pro for the team" })).toHaveAttribute(
      "href",
      "/account/billing",
    );
    expect(screen.getByTestId("team-plan")).toHaveTextContent("Not paid yet");
  });

  it("member: sees the team and can leave, nothing to manage", () => {
    const member = { ...owner, role: "member" as const, invites: [] };
    render(<TeamView state={{ available: true, team: member }} servers={[]} />);
    expect(screen.getByText(/owner@example.com manages this team/)).toBeVisible();
    expect(screen.getByRole("button", { name: "Leave team" })).toBeVisible();
    expect(screen.queryByRole("button", { name: "Remove" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Delete team" })).not.toBeInTheDocument();
  });
});

describe("JoinView (AC14)", () => {
  it("joins as the signed-in account", () => {
    render(<JoinView email="dev@example.com" token={"t".repeat(43)} />);
    expect(screen.getByText("dev@example.com")).toBeVisible();
    expect(screen.getByRole("button", { name: "Join the team" })).toBeVisible();
  });

  it("explains an incomplete link", () => {
    render(<JoinView email="dev@example.com" token={null} />);
    expect(screen.getByTestId("join-no-token")).toBeVisible();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });
});

describe("team prices (AC3, AC13)", () => {
  it("works out the total per period", () => {
    expect(teamTotal(TEAM_PRICES, 2, "monthly")).toBe(13.98);
    expect(teamTotal(TEAM_PRICES, 5, "yearly")).toBe(349.5);
    expect(usd(teamTotal(TEAM_PRICES, 3, "monthly"))).toBe("$20.97");
  });
});

describe("pressing Remove asks first", () => {
  it("cancels when the confirmation is declined", () => {
    const confirm = vi.spyOn(window, "confirm").mockReturnValue(false);
    render(<TeamView state={{ available: true, team: owner }} servers={servers} />);
    fireEvent.click(screen.getByRole("button", { name: "Remove" }));
    expect(confirm).toHaveBeenCalledWith("Remove dev@example.com from the team?");
    confirm.mockRestore();
  });
});
