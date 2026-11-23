// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const listSupportTickets = vi.fn();
const getSupportTicket = vi.fn();
const fetchSupportScreenshot = vi.fn();
const getSession = vi.fn();
const notFound = vi.fn(() => {
  throw new Error("NOT_FOUND");
});

vi.mock("next/navigation", () => ({ notFound: () => notFound(), redirect: vi.fn() }));
vi.mock("next/server", () => ({ connection: async () => {} }));
vi.mock("@/server/guard", () => ({ requireSession: async () => ({ accessToken: "a" }) }));
vi.mock("@/server/session", () => ({
  getSession: () => getSession(),
  isSignedIn: (session: { accessToken?: string }) => Boolean(session.accessToken),
}));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/support-api", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/server/support-api")>()),
  listSupportTickets: (...args: unknown[]) => listSupportTickets(...args),
  getSupportTicket: (...args: unknown[]) => getSupportTicket(...args),
  fetchSupportScreenshot: (...args: unknown[]) => fetchSupportScreenshot(...args),
}));

import { GET as getScreenshot } from "./[id]/screenshots/[index]/route";
import AdminSupportDetailPage from "./[id]/page";
import AdminSupportPage from "./page";

const ID = "64b0000000000000000000aa";
const params = (value: Record<string, string>) => Promise.resolve(value);
const row = {
  id: ID,
  category: "bug",
  subject: "Blank log",
  message: "Nothing shows.",
  areas: ["jenkins"],
  impact: "blocked",
  screenshotCount: 1,
  status: "open",
  createdAt: "2026-11-23T00:00:00.000Z",
  updatedAt: "2026-11-23T00:00:00.000Z",
  replyEmail: "sam@acme.dev",
  userEmail: "sam@acme.dev",
  appVersion: null,
  buildNumber: null,
  tool: null,
  platform: null,
  serverHost: null,
  screenshots: [
    {
      index: 0,
      mime: "image/png",
      size: 100,
      hash: "abc",
      createdAt: "2026-11-23T00:00:00.000Z",
      deletedAt: null,
    },
  ],
};

beforeEach(() => {
  for (const mock of [
    listSupportTickets,
    getSupportTicket,
    fetchSupportScreenshot,
    getSession,
    notFound,
  ]) {
    mock.mockReset();
  }
  notFound.mockImplementation(() => {
    throw new Error("NOT_FOUND");
  });
});

describe("the support queue page", () => {
  it("is a 404 page for a non-admin (the backend's plain 404)", async () => {
    listSupportTickets.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    await expect(AdminSupportPage({ searchParams: params({}) } as never)).rejects.toThrow(
      "NOT_FOUND",
    );
  });

  it("defaults to open and ignores an unknown status", async () => {
    listSupportTickets.mockResolvedValue({ ok: true, value: [] });
    await AdminSupportPage({ searchParams: params({ status: "evil" }) } as never);
    expect(listSupportTickets).toHaveBeenCalledWith("a", "open");
    await AdminSupportPage({ searchParams: params({ status: "closed" }) } as never);
    expect(listSupportTickets).toHaveBeenLastCalledWith("a", "closed");
  });

  it("shows an unreachable backend as an error, not a 404", async () => {
    listSupportTickets.mockResolvedValue({ ok: false, failure: { kind: "network" } });
    await expect(AdminSupportPage({ searchParams: params({}) } as never)).resolves.toBeTruthy();
  });
});

describe("the support detail page", () => {
  it("404s a bad id or a missing ticket", async () => {
    await expect(
      AdminSupportDetailPage({ params: params({ id: "../x" }) } as never),
    ).rejects.toThrow("NOT_FOUND");
    getSupportTicket.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    await expect(AdminSupportDetailPage({ params: params({ id: ID }) } as never)).rejects.toThrow(
      "NOT_FOUND",
    );
  });

  it("renders the detail for an admin", async () => {
    getSupportTicket.mockResolvedValue({ ok: true, value: row });
    const page = await AdminSupportDetailPage({ params: params({ id: ID }) } as never);
    expect(page).toBeTruthy();
    expect(getSupportTicket).toHaveBeenCalledWith("a", ID);
  });
});

describe("the screenshot route (US-SUP-06/07)", () => {
  const request = new Request("http://site.test/admin/support/x/screenshots/0");

  it("is a plain 404 without a session, with a bad id, or a bad index", async () => {
    for (const [id, index, signedIn] of [
      ["../x", "0", true],
      [ID, "abc", true],
      [ID, "0", false],
    ] as const) {
      getSession.mockReturnValue(signedIn ? { accessToken: "a" } : {});
      const response = await getScreenshot(request, { params: params({ id, index }) } as never);
      expect(response.status).toBe(404);
      expect(response.headers.get("cache-control")).toBe("no-store");
    }
    expect(fetchSupportScreenshot).not.toHaveBeenCalled();
  });

  it("does not expose a non-admin's 404 from the backend", async () => {
    getSession.mockReturnValue({ accessToken: "a" });
    fetchSupportScreenshot.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    const response = await getScreenshot(request, {
      params: params({ id: ID, index: "0" }),
    } as never);
    expect(response.status).toBe(404);
  });

  it("streams one image with no-store, nosniff and no token", async () => {
    getSession.mockReturnValue({ accessToken: "a" });
    fetchSupportScreenshot.mockResolvedValue({
      ok: true,
      value: { bytes: new Uint8Array([1, 2, 3]).buffer, contentType: "image/png; charset=binary" },
    });
    const response = await getScreenshot(request, {
      params: params({ id: ID, index: "0" }),
    } as never);
    expect(response.status).toBe(200);
    expect(response.headers.get("content-type")).toBe("image/png");
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
    expect(fetchSupportScreenshot).toHaveBeenCalledWith("access-1", ID, 0);
  });
});
