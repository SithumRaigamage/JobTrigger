// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { failureFor } from "./backend-client";
import { createCheckout, createPortalLink, isPaddleUrl } from "./billing-api";

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

describe("createCheckout", () => {
  it("asks the backend for a transaction and sends only the interval", async () => {
    fetchMock.mockResolvedValue(json({ transactionId: "txn_1", environment: "sandbox" }));

    const result = await createCheckout("access-1", "yearly");

    expect(result).toEqual({ ok: true, value: { transactionId: "txn_1", environment: "sandbox" } });
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe("http://backend.test/api/billing/paddle/checkout");
    expect(init!.method).toBe("POST");
    // No user id, price or amount from the website: the backend decides.
    expect(JSON.parse(String(init!.body))).toEqual({ interval: "yearly" });
    expect((init!.headers as Record<string, string>)["x-auth-token"]).toBe("access-1");
  });

  it("sends a discount code with the interval, and nothing else (US-PROMO-04)", async () => {
    fetchMock.mockResolvedValue(json({ transactionId: "txn_2", environment: "sandbox" }));

    await createCheckout("access-1", "yearly", "SAVE20");

    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe("http://backend.test/api/billing/paddle/checkout");
    expect(JSON.parse(String(init!.body))).toEqual({ interval: "yearly", code: "SAVE20" });
  });

  it("reports Pro-already and unavailable billing as their own failures", async () => {
    fetchMock.mockResolvedValueOnce(json({ code: "ALREADY_SUBSCRIBED", message: "x" }, 409));
    expect(await createCheckout("t", "monthly")).toEqual({
      ok: false,
      failure: { kind: "alreadySubscribed" },
    });

    fetchMock.mockResolvedValueOnce(json({ message: "off" }, 503));
    expect(await createCheckout("t", "monthly")).toEqual({
      ok: false,
      failure: { kind: "billingUnavailable" },
    });
  });
});

describe("createPortalLink", () => {
  it("returns the backend's portal link", async () => {
    fetchMock.mockResolvedValue(
      json({ url: "https://customer-portal.paddle.com/cpl_1?token=abc" }),
    );
    expect(await createPortalLink("t")).toEqual({
      ok: true,
      value: "https://customer-portal.paddle.com/cpl_1?token=abc",
    });
  });

  it("refuses a link that isn't https on paddle.com", async () => {
    for (const url of [
      "http://customer-portal.paddle.com/x",
      "https://evil.example.com/paddle.com",
      "https://paddle.com.evil.example/x",
    ]) {
      fetchMock.mockResolvedValueOnce(json({ url }));
      expect(await createPortalLink("t")).toEqual({ ok: false, failure: { kind: "unexpected" } });
    }
  });

  it("says there's no web subscription as not found", async () => {
    fetchMock.mockResolvedValue(json({ message: "none" }, 404));
    expect(await createPortalLink("t")).toEqual({ ok: false, failure: { kind: "notFound" } });
  });
});

describe("isPaddleUrl", () => {
  it("accepts paddle.com and its subdomains over https only", () => {
    expect(isPaddleUrl("https://paddle.com/x")).toBe(true);
    expect(isPaddleUrl("https://sandbox-customer-portal.paddle.com/x")).toBe(true);
    expect(isPaddleUrl("http://paddle.com/x")).toBe(false);
    expect(isPaddleUrl("https://notpaddle.com/x")).toBe(false);
    expect(isPaddleUrl("not a url")).toBe(false);
  });
});

describe("failureFor 409 and 503", () => {
  it("leaves other 409s and 503s' neighbours alone", () => {
    expect(failureFor(409, { message: "Conflict" }, null)).toEqual({ kind: "server", status: 409 });
    expect(failureFor(502, {}, null)).toEqual({ kind: "server", status: 502 });
  });
});
