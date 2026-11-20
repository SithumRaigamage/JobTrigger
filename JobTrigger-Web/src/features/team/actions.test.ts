// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

// US-SUB-11 AC12–AC14: the actions validate input and only forward.

const { api, revalidatePath, redirect } = vi.hoisted(() => ({
  api: {
    createTeam: vi.fn(),
    inviteMember: vi.fn(),
    joinTeam: vi.fn(),
    setSeats: vi.fn(),
    teamCheckout: vi.fn(),
    removeMember: vi.fn(),
    shareServer: vi.fn(),
  },
  revalidatePath: vi.fn(),
  redirect: vi.fn((_path: string): never => {
    throw new Error("NEXT_REDIRECT");
  }),
}));

vi.mock("next/cache", () => ({ revalidatePath: (p: string) => revalidatePath(p) }));
vi.mock("next/navigation", () => ({ redirect: (p: string) => redirect(p) }));
vi.mock("@/server/guard", () => ({ requireSession: async () => ({ accessToken: "a" }) }));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/team-api", () => ({
  ...Object.fromEntries(
    Object.entries(api).map(([name, fn]) => [name, (...args: unknown[]) => fn(...args)]),
  ),
  cancelInvite: vi.fn(),
  deleteTeam: vi.fn(),
  leaveTeam: vi.fn(),
  unshareServer: vi.fn(),
}));

import {
  createTeamAction,
  inviteAction,
  joinTeamAction,
  removeMemberAction,
  setSeatsAction,
  shareServerAction,
  startTeamCheckoutAction,
} from "./actions";

const form = (fields: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(fields)) data.set(key, value);
  return data;
};
const okTeam = { ok: true, value: {} };

beforeEach(() => {
  for (const fn of Object.values(api)) fn.mockReset();
  revalidatePath.mockReset();
  redirect.mockClear();
});

describe("team actions", () => {
  it("creates with a trimmed name and refreshes the page", async () => {
    api.createTeam.mockResolvedValue(okTeam);
    expect(await createTeamAction({}, form({ name: "  Platform " }))).toEqual({});
    expect(api.createTeam).toHaveBeenCalledWith("access-1", "Platform");
    expect(revalidatePath).toHaveBeenCalledWith("/account/team");
  });

  it("refuses a blank or long name, a bad email, bad seats and ids without calling", async () => {
    expect((await createTeamAction({}, form({ name: " " }))).error).toMatch(/1 to 60/);
    expect((await createTeamAction({}, form({ name: "x".repeat(61) }))).error).toMatch(/1 to 60/);
    expect((await inviteAction({}, form({ email: "nope" }))).error).toBe("Enter an email address.");
    expect((await setSeatsAction({}, form({ seats: "1" }))).error).toBe("Choose 2 to 100 seats.");
    expect((await setSeatsAction({}, form({ seats: "101" }))).error).toBe("Choose 2 to 100 seats.");
    expect((await removeMemberAction({}, form({ userId: "../x" }))).error).toMatch(
      /couldn't be found/,
    );
    expect((await shareServerAction({}, form({ credentialId: "a b" }))).error).toMatch(/Jenkins/);
    expect(api.createTeam).not.toHaveBeenCalled();
    expect(api.inviteMember).not.toHaveBeenCalled();
    expect(api.setSeats).not.toHaveBeenCalled();
    expect(api.removeMember).not.toHaveBeenCalled();
  });

  it("confirms an invite and shows the backend's refusal", async () => {
    api.inviteMember.mockResolvedValueOnce(okTeam);
    expect(await inviteAction({}, form({ email: "new@example.com" }))).toEqual({
      done: "Invite sent to new@example.com.",
    });
    api.inviteMember.mockResolvedValueOnce({
      ok: false,
      failure: { kind: "explained", status: 403, message: "Every seat is taken." },
    });
    expect(await inviteAction({}, form({ email: "b@example.com" }))).toEqual({
      error: "Every seat is taken.",
    });
  });

  it("joins and then goes to the team page (AC14)", async () => {
    api.joinTeam.mockResolvedValue(okTeam);
    await expect(joinTeamAction({}, form({ token: "t".repeat(43) }))).rejects.toThrow(
      "NEXT_REDIRECT",
    );
    expect(redirect).toHaveBeenCalledWith("/account/team");
    expect((await joinTeamAction({}, form({ token: "short" }))).error).toMatch(/isn't valid/);
  });

  it("team checkout passes only a valid period and seats (AC13)", async () => {
    api.teamCheckout.mockResolvedValue({
      ok: true,
      value: { transactionId: "txn", environment: "sandbox" },
    });
    expect(await startTeamCheckoutAction("yearly", 5)).toEqual({
      transactionId: "txn",
      environment: "sandbox",
    });
    expect(api.teamCheckout).toHaveBeenCalledWith("access-1", "yearly", 5);
    expect(await startTeamCheckoutAction("weekly", 5)).toEqual({
      error: "Choose monthly or yearly.",
    });
    expect(await startTeamCheckoutAction("monthly", 1)).toEqual({
      error: "Choose 2 to 100 seats.",
    });
    expect(api.teamCheckout).toHaveBeenCalledTimes(1);
  });
});
