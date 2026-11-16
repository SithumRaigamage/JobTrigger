// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { failureFor } from "./backend-client";
import { getSubscription } from "./subscription-api";

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

const pro = {
  plan: "pro",
  billingEnabled: true,
  status: "billing_issue",
  source: "app_store",
  productId: "pro_yearly",
  periodEnd: "2027-03-03T00:00:00.000Z",
  willRenew: false,
  manageOnWeb: false,
  limits: { maxCredentialsTotal: null, maxCredentialsPerTool: 25, maxPinnedJobs: null },
  features: { multiTool: true, backgroundWatch: true, homeWidget: true, insights: true },
  primaryCredentialId: null,
};

describe("getSubscription", () => {
  it("reads the plan with the x-auth-token header and maps the wire values", async () => {
    fetchMock.mockResolvedValue(json(pro));

    const result = await getSubscription("access-1");

    expect(result).toEqual({
      ok: true,
      value: {
        plan: "pro",
        billingEnabled: true,
        state: "billingIssue",
        source: "appStore",
        periodEnd: "2027-03-03T00:00:00.000Z",
        willRenew: false,
        manageOnWeb: false,
        limits: { maxCredentialsTotal: null, maxCredentialsPerTool: 25, maxPinnedJobs: null },
        features: { multiTool: true, backgroundWatch: true, homeWidget: true, insights: true },
      },
    });
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe("http://backend.test/api/subscription");
    expect((init!.headers as Record<string, string>)["x-auth-token"]).toBe("access-1");
    expect(init!.method ?? "GET").toBe("GET");
  });

  it("reads a Free user, and tolerates values it doesn't know yet", async () => {
    fetchMock.mockResolvedValue(
      json({
        ...pro,
        plan: "team",
        status: "something_new",
        source: "carrier_pigeon",
        periodEnd: null,
        limits: { maxCredentialsTotal: 1, maxCredentialsPerTool: 1, maxPinnedJobs: 3 },
        features: {},
      }),
    );

    const result = await getSubscription("t");

    expect(result.ok && result.value).toMatchObject({
      plan: "free",
      state: "none",
      source: null,
      limits: { maxCredentialsTotal: 1, maxPinnedJobs: 3 },
      features: { multiTool: false, insights: false },
    });
  });

  it("returns a failure, not a throw, when the backend has no such endpoint", async () => {
    fetchMock.mockResolvedValue(json({ message: "Not found" }, 404));
    expect(await getSubscription("t")).toEqual({ ok: false, failure: { kind: "notFound" } });
  });

  it("fails as unexpected on a body of the wrong shape", async () => {
    fetchMock.mockResolvedValue(json({ plan: "pro" }));
    expect(await getSubscription("t")).toEqual({ ok: false, failure: { kind: "unexpected" } });
  });
});

describe("failureFor 403 (P20-31)", () => {
  it("maps PLAN_LIMIT to a plan-limit failure with the backend's limit", () => {
    expect(
      failureFor(403, { code: "PLAN_LIMIT", limit: "maxCredentialsTotal", message: "x" }, null),
    ).toEqual({ kind: "planLimit", limit: "maxCredentialsTotal" });
    expect(failureFor(403, { code: "PLAN_LIMIT" }, null)).toEqual({
      kind: "planLimit",
      limit: "unknown",
    });
  });

  it("leaves every other 403 exactly as it was", () => {
    expect(failureFor(403, { message: "Forbidden" }, null)).toEqual({
      kind: "server",
      status: 403,
    });
    expect(failureFor(403, { code: "SOMETHING_ELSE" }, "req-1")).toEqual({
      kind: "server",
      status: 403,
      requestId: "req-1",
    });
  });
});
