// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { explainedFailureFor } from "./backend-client";
import { getTeam, inviteMember, joinTeam, teamCheckout } from "./team-api";

// US-SUB-11 AC12–AC14 (website side of /api/team).

vi.mock("./config", () => ({
  getConfig: () => ({ backendUrl: "http://backend.test", sessionSecret: "x", siteUrl: "" }),
}));

const fetchMock = vi.fn<typeof fetch>();
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

beforeEach(() => vi.stubGlobal("fetch", fetchMock));
afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
});

const team = {
  id: "t1",
  name: "Platform",
  role: "owner",
  seats: 3,
  seatsUsed: 2,
  active: true,
  billing: {
    status: "active",
    period: "yearly",
    periodEnd: "2027-01-01T00:00:00.000Z",
    willRenew: true,
  },
  members: [
    { userId: "u1", email: "owner@example.com", owner: true, joinedAt: "2026-11-20T00:00:00.000Z" },
  ],
  invites: [{ id: "i1", email: "new@example.com", expiresAt: "2026-11-27T00:00:00.000Z" }],
  sharedServerIds: ["c1"],
  prices: { monthly: 6.99, yearly: 69.9, minSeats: 2, maxSeats: 100 },
};

describe("getTeam", () => {
  it("reads the team with x-auth-token", async () => {
    fetchMock.mockResolvedValue(json(team));
    const result = await getTeam("access-1");
    expect(result).toEqual({ ok: true, value: { available: true, team } });
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(url).toBe("http://backend.test/api/team");
    expect((init?.headers as Record<string, string>)["x-auth-token"]).toBe("access-1");
  });

  it("no team is null; a 404 means teams are off", async () => {
    fetchMock.mockResolvedValueOnce(json(null));
    expect(await getTeam("a")).toEqual({ ok: true, value: { available: true, team: null } });
    fetchMock.mockResolvedValueOnce(json({ message: "Not found" }, 404));
    expect(await getTeam("a")).toEqual({ ok: true, value: { available: false } });
  });
});

describe("team refusals keep the backend's sentence", () => {
  it.each([
    [403, "SEATS_FULL", "Every seat is taken. Add seats to invite someone else."],
    [404, "INVITE_UNKNOWN", "This invite link isn't valid."],
    [410, "INVITE_EXPIRED", "This invite has expired. Ask for a new one."],
    [409, "ALREADY_IN_TEAM", "You're already in a team."],
  ])("%i %s", async (status, code, message) => {
    fetchMock.mockResolvedValue(json({ code, message }, status));
    const result = await joinTeam("a", "x".repeat(43));
    expect(result).toEqual({ ok: false, failure: { kind: "explained", status, code, message } });
  });

  it("sends the email and the token in the body", async () => {
    fetchMock.mockResolvedValue(json(team, 201));
    await inviteMember("a", "new@example.com");
    expect(JSON.parse(String(fetchMock.mock.calls[0]![1]!.body))).toEqual({
      email: "new@example.com",
    });
  });

  it("other calls still explain only their original statuses", () => {
    expect(explainedFailureFor(403, { message: "No" })).toBe(null);
    expect(explainedFailureFor(403, { message: "No" }, [403])).toEqual({
      kind: "explained",
      status: 403,
      message: "No",
    });
  });
});

describe("teamCheckout", () => {
  it("posts period and seats and returns the transaction", async () => {
    fetchMock.mockResolvedValue(json({ transactionId: "txn_team", environment: "sandbox" }));
    expect(await teamCheckout("a", "monthly", 4)).toEqual({
      ok: true,
      value: { transactionId: "txn_team", environment: "sandbox" },
    });
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(url).toBe("http://backend.test/api/team/checkout");
    expect(JSON.parse(String(init!.body))).toEqual({ period: "monthly", seats: 4 });
  });
});
