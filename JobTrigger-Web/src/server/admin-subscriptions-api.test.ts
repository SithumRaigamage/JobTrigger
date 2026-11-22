// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  grantAdminPlan,
  isAdminSubscriptionId,
  listAdminSubscriptions,
  revokeAdminPlan,
} from "./admin-subscriptions-api";

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

const ID = "64b0000000000000000000aa";
const row = {
  userId: ID,
  email: "journey1@example.com",
  plan: "pro",
  status: "active",
  source: "admin",
  productId: null,
  periodEnd: null,
  willRenew: false,
  sources: {
    store: null,
    web: null,
    grant: {
      plan: "pro",
      status: "active",
      source: "admin",
      productId: null,
      periodEnd: null,
      willRenew: false,
    },
    student: null,
  },
  createdAt: "2026-11-18T00:00:00.000Z",
};

describe("listAdminSubscriptions", () => {
  it("asks for the plan and the search, and unwraps the items", async () => {
    fetchMock.mockResolvedValue(json({ items: [row] }));
    const result = await listAdminSubscriptions("tok", { plan: "free", q: "journey & co" });
    expect(result.ok && result.value.items).toHaveLength(1);
    expect(result.ok && result.value.items[0]).toMatchObject({
      email: "journey1@example.com",
      plan: "pro",
      state: "active",
      source: "admin",
      sources: { store: null, grant: { state: "active" } },
    });
    // An older backend sends no codes: the console shows no code card.
    expect(result.ok && result.value.codes).toEqual([]);
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe(
      "http://backend.test/api/admin/subscriptions?plan=free&q=journey+%26+co",
    );
    expect((init!.headers as Record<string, string>)["x-auth-token"]).toBe("tok");
  });

  it("leaves q out when empty", async () => {
    fetchMock.mockResolvedValue(json({ items: [] }));
    await listAdminSubscriptions("tok", { plan: "all", q: "" });
    expect(String(fetchMock.mock.calls[0]![0])).toBe(
      "http://backend.test/api/admin/subscriptions?plan=all",
    );
  });

  it("a non-admin's 404 is a notFound failure", async () => {
    fetchMock.mockResolvedValue(json({ message: "Not found" }, 404));
    expect(await listAdminSubscriptions("tok", { plan: "all", q: "" })).toEqual({
      ok: false,
      failure: { kind: "notFound" },
    });
  });

  it("maps an unknown status and source to safe values", async () => {
    fetchMock.mockResolvedValue(
      json({ items: [{ ...row, status: "mystery", source: "mystery" }] }),
    );
    const result = await listAdminSubscriptions("tok", { plan: "all", q: "" });
    expect(result.ok && result.value.items[0]).toMatchObject({ state: "none", source: null });
  });

  it("parses each code's counts, and an odd one without failing the page (US-PROMO-05)", async () => {
    fetchMock.mockResolvedValue(
      json({
        items: [],
        codes: [
          {
            code: "LAUNCH30",
            kind: "pro",
            days: 30,
            redemptions: 3,
            maxRedemptions: 50,
            remaining: 47,
            expiresAt: null,
            expired: false,
          },
          {
            code: "SAVE20",
            kind: "checkout",
            days: null,
            redemptions: null,
            maxRedemptions: null,
            remaining: null,
            expiresAt: "2027-01-31T23:59:59.999Z",
            expired: false,
          },
          { code: "ODD", kind: "mystery" },
        ],
      }),
    );

    const result = await listAdminSubscriptions("tok", { plan: "all", q: "" });
    const codes = result.ok ? result.value.codes : [];
    expect(codes[0]).toMatchObject({ code: "LAUNCH30", redemptions: 3, remaining: 47 });
    expect(codes[1]).toMatchObject({ kind: "checkout", redemptions: null, remaining: null });
    expect(codes[2]).toMatchObject({
      kind: "pro",
      redemptions: null,
      remaining: null,
      expired: false,
    });
  });
});

describe("grant and revoke", () => {
  it("posts to the grant route, with days only when bounded", async () => {
    // A new Response per call: a body can only be read once.
    fetchMock.mockImplementation(async () => json(row));
    await grantAdminPlan("tok", ID, 30);
    await grantAdminPlan("tok", ID, null);
    const calls = fetchMock.mock.calls.map(([url, init]) => [
      String(url),
      init!.method ?? "GET",
      init!.body ? JSON.parse(String(init!.body)) : null,
    ]);
    expect(calls).toEqual([
      [`http://backend.test/api/admin/subscriptions/${ID}/grant`, "POST", { days: 30 }],
      [`http://backend.test/api/admin/subscriptions/${ID}/grant`, "POST", {}],
    ]);
  });

  it("posts to the revoke route with no body", async () => {
    fetchMock.mockResolvedValue(json({ ...row, plan: "free" }));
    await revokeAdminPlan("tok", ID);
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe(`http://backend.test/api/admin/subscriptions/${ID}/revoke`);
    expect(init!.method).toBe("POST");
  });

  it("only accepts the backend's id shape", () => {
    expect(isAdminSubscriptionId(ID)).toBe(true);
    for (const bad of ["", "../x", "abc", `${ID}/grant`, `${ID}?x=1`, "g".repeat(24)]) {
      expect(isAdminSubscriptionId(bad), bad).toBe(false);
    }
  });
});
