// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const createCheckout = vi.fn();
const createPortalLink = vi.fn();

vi.mock("@/server/guard", () => ({ requireSession: async () => ({ accessToken: "a" }) }));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/billing-api", () => ({
  createCheckout: (...args: unknown[]) => createCheckout(...args),
  createPortalLink: (...args: unknown[]) => createPortalLink(...args),
}));

import { openPortalAction, startCheckoutAction } from "./actions";

beforeEach(() => {
  createCheckout.mockReset();
  createPortalLink.mockReset();
});

describe("startCheckoutAction", () => {
  it("passes only a valid interval to the backend and returns the transaction", async () => {
    createCheckout.mockResolvedValue({
      ok: true,
      value: { transactionId: "txn_1", environment: "sandbox" },
    });

    expect(await startCheckoutAction("monthly")).toEqual({
      transactionId: "txn_1",
      environment: "sandbox",
    });
    expect(createCheckout).toHaveBeenCalledWith("access-1", "monthly");
  });

  it("refuses anything else without calling the backend", async () => {
    expect(await startCheckoutAction("lifetime")).toEqual({ error: "Choose monthly or yearly." });
    expect(createCheckout).not.toHaveBeenCalled();
  });

  it("says you already have Pro instead of opening a second checkout", async () => {
    createCheckout.mockResolvedValue({ ok: false, failure: { kind: "alreadySubscribed" } });
    expect(await startCheckoutAction("yearly")).toEqual({
      error: "You already have Pro. There is nothing more to buy.",
    });
  });
});

describe("openPortalAction", () => {
  it("returns the portal link, or the failure's copy", async () => {
    createPortalLink.mockResolvedValueOnce({ ok: true, value: "https://x.paddle.com/p" });
    expect(await openPortalAction()).toEqual({ url: "https://x.paddle.com/p" });

    createPortalLink.mockResolvedValueOnce({ ok: false, failure: { kind: "notFound" } });
    expect(await openPortalAction()).toEqual({
      error: "That couldn't be found — it may have been removed.",
    });
  });
});
