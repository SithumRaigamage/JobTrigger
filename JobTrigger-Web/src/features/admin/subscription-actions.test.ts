// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const grantAdminPlan = vi.fn();
const revokeAdminPlan = vi.fn();
const redirect = vi.fn((url: string) => {
  throw new Error(`REDIRECT ${url}`);
});

vi.mock("next/cache", () => ({ revalidatePath: vi.fn() }));
vi.mock("next/navigation", () => ({ redirect: (url: string) => redirect(url) }));
vi.mock("@/server/guard", () => ({ requireSession: async () => ({ accessToken: "a" }) }));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/admin-subscriptions-api", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/server/admin-subscriptions-api")>()),
  grantAdminPlan: (...args: unknown[]) => grantAdminPlan(...args),
  revokeAdminPlan: (...args: unknown[]) => revokeAdminPlan(...args),
}));

import { grantPlanAction, revokePlanAction } from "./subscription-actions";

const ID = "64b0000000000000000000aa";
const form = (values: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(values)) data.set(key, value);
  return data;
};

beforeEach(() => {
  grantAdminPlan.mockReset();
  revokeAdminPlan.mockReset();
  redirect.mockClear();
});

describe("grantPlanAction", () => {
  it("refuses an id of the wrong shape before calling the backend", async () => {
    const state = await grantPlanAction({}, form({ id: "../../x", days: "30" }));
    expect(state.error).toBe("That account couldn't be found.");
    expect(grantAdminPlan).not.toHaveBeenCalled();
  });

  it("grants for the given days and goes back with a notice", async () => {
    grantAdminPlan.mockResolvedValue({ ok: true, value: {} });
    await expect(grantPlanAction({}, form({ id: ID, days: "30" }))).rejects.toThrow(
      "REDIRECT /admin/subscriptions?notice=granted",
    );
    expect(grantAdminPlan).toHaveBeenCalledWith("access-1", ID, 30);
  });

  it("an empty days field grants Pro with no end", async () => {
    grantAdminPlan.mockResolvedValue({ ok: true, value: {} });
    await expect(grantPlanAction({}, form({ id: ID, days: "  " }))).rejects.toThrow(
      "REDIRECT /admin/subscriptions?notice=granted",
    );
    expect(grantAdminPlan).toHaveBeenCalledWith("access-1", ID, null);
  });

  it("rejects days that are not a bounded whole number", async () => {
    for (const days of ["0", "-1", "1.5", "3651", "soon"]) {
      const state = await grantPlanAction({}, form({ id: ID, days }));
      expect(state.error, days).toMatch(/whole number/);
    }
    expect(grantAdminPlan).not.toHaveBeenCalled();
  });

  it("shows the backend's sentence when it refuses", async () => {
    grantAdminPlan.mockResolvedValue({
      ok: false,
      failure: { kind: "explained", status: 400, message: "That account is protected." },
    });
    expect((await grantPlanAction({}, form({ id: ID, days: "30" }))).error).toBe(
      "That account is protected.",
    );
    expect(redirect).not.toHaveBeenCalled();
  });
});

describe("revokePlanAction", () => {
  it("revokes and goes back with a notice", async () => {
    revokeAdminPlan.mockResolvedValue({ ok: true, value: {} });
    await expect(revokePlanAction({}, form({ id: ID }))).rejects.toThrow(
      "REDIRECT /admin/subscriptions?notice=revoked",
    );
    expect(revokeAdminPlan).toHaveBeenCalledWith("access-1", ID);
  });

  it("refuses a bad id", async () => {
    expect((await revokePlanAction({}, form({ id: "nope" }))).error).toBe(
      "That account couldn't be found.",
    );
  });

  it("a non-admin gets the not-found message, nothing else", async () => {
    revokeAdminPlan.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    expect((await revokePlanAction({}, form({ id: ID }))).error).toBe(
      "That couldn't be found — it may have been removed.",
    );
  });
});
