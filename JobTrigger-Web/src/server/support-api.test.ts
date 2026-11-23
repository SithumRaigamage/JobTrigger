// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  createSupportTicket,
  createToolRequest,
  fetchSupportScreenshot,
  getSupportTicket,
  isTicketId,
  listSupportTickets,
  updateSupportStatus,
} from "./support-api";

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
  id: ID,
  category: "bug",
  subject: "Blank log",
  message: "Nothing shows.",
  areas: ["jenkins", "phone"],
  impact: "blocked",
  screenshotCount: 1,
  status: "open",
  createdAt: "2026-11-23T00:00:00.000Z",
  updatedAt: "2026-11-23T00:00:00.000Z",
  replyEmail: "sam@acme.dev",
  userEmail: "sam@acme.dev",
  appVersion: null,
  buildNumber: null,
  tool: "jenkins",
  platform: "android",
  serverHost: "https://jenkins.acme.dev",
};

describe("createSupportTicket (US-SUP-05/06)", () => {
  it("posts the options and base64 screenshots with the app's auth header", async () => {
    fetchMock.mockResolvedValue(json({ ticket: { id: ID } }, 201));
    const result = await createSupportTicket("tok", {
      category: "bug",
      subject: "Blank log",
      message: "Nothing shows.",
      areas: ["jenkins", "phone"],
      impact: "blocked",
      replyEmail: "sam@acme.dev",
      screenshots: [{ name: "shot.png", data: "iVBORw0KGgo=" }],
    });

    expect(result.ok && result.value).toEqual({ id: ID });
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe("http://backend.test/api/support/tickets");
    expect(init?.method).toBe("POST");
    expect((init?.headers as Record<string, string>)["x-auth-token"]).toBe("tok");
    expect(JSON.parse(String(init?.body))).toMatchObject({
      category: "bug",
      areas: ["jenkins", "phone"],
      impact: "blocked",
      screenshots: [{ name: "shot.png", data: "iVBORw0KGgo=" }],
    });
  });

  it("shows the backend's own reason for a bad image", async () => {
    fetchMock.mockResolvedValue(
      json({ message: "Screenshots must be JPG or PNG images.", code: "wrongType" }, 415),
    );
    const result = await createSupportTicket("tok", {
      category: "bug",
      subject: "S",
      message: "M",
      areas: [],
      impact: "minor",
      replyEmail: "sam@acme.dev",
      screenshots: [],
    });
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.failure).toMatchObject({ kind: "explained", status: 415 });
  });
});

describe("the owner's support API (US-SUP-07)", () => {
  it("lists tickets newest first, filtered by status, with the triage fields", async () => {
    fetchMock.mockResolvedValue(json({ tickets: [row] }));
    const result = await listSupportTickets("tok", "open");
    expect(result.ok && result.value).toHaveLength(1);
    expect(result.ok && result.value[0]).toMatchObject({
      areas: ["jenkins", "phone"],
      impact: "blocked",
      screenshotCount: 1,
    });
    expect(String(fetchMock.mock.calls[0]![0])).toBe(
      "http://backend.test/api/admin/support/tickets?status=open",
    );
  });

  it("parses an older ticket that has no new fields", async () => {
    const older = { ...row };
    for (const key of ["areas", "impact", "screenshotCount", "createdAt", "updatedAt"]) {
      delete (older as Record<string, unknown>)[key];
    }
    fetchMock.mockResolvedValue(json({ tickets: [older] }));
    const result = await listSupportTickets("tok", "all");
    expect(result.ok).toBe(true);
    expect(result.ok && result.value[0]).toMatchObject({ areas: [], impact: "minor" });
  });

  it("reads the detail with screenshot metadata but never bytes", async () => {
    const detail = {
      ...row,
      screenshots: [
        {
          index: 0,
          mime: "image/png",
          size: 2048,
          hash: "abc",
          createdAt: "2026-11-23T00:00:00.000Z",
          deletedAt: null,
        },
      ],
    };
    fetchMock.mockResolvedValue(json({ ticket: detail }));
    const result = await getSupportTicket("tok", ID);
    expect(result.ok).toBe(true);
    expect(result.ok && result.value.screenshots?.[0]).toMatchObject({
      index: 0,
      mime: "image/png",
    });
    expect(result.ok && JSON.stringify(result.value)).not.toContain("data");
  });

  it("patches a status and unwraps the updated ticket", async () => {
    fetchMock.mockResolvedValue(json({ ticket: { ...row, status: "closed" } }));
    const result = await updateSupportStatus("tok", ID, "closed");
    expect(result.ok && result.value.status).toBe("closed");
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe(`http://backend.test/api/admin/support/tickets/${ID}`);
    expect(init?.method).toBe("PATCH");
    expect(JSON.parse(String(init?.body))).toEqual({ status: "closed" });
  });

  it("fetches one screenshot's bytes through the binary client", async () => {
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 1, 2, 3]);
    fetchMock.mockResolvedValue(
      new Response(png, { status: 200, headers: { "content-type": "image/png" } }),
    );
    const result = await fetchSupportScreenshot("tok", ID, 1);
    expect(result.ok && result.value.contentType).toContain("image/png");
    expect(result.ok && new Uint8Array(result.value.bytes)).toEqual(png);
    expect(String(fetchMock.mock.calls[0]![0])).toBe(
      `http://backend.test/api/admin/support/tickets/${ID}/screenshots/1`,
    );
  });

  it("a non-admin's 404 stays a notFound failure", async () => {
    fetchMock.mockResolvedValue(json({ message: "Not found" }, 404));
    const result = await getSupportTicket("tok", ID);
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.failure).toEqual({ kind: "notFound" });
  });
});

describe("id shapes", () => {
  it("only accepts the backend's ObjectId shape, for safe paths", () => {
    expect(isTicketId(ID)).toBe(true);
    expect(isTicketId("../tickets")).toBe(false);
    expect(isTicketId("not-an-id")).toBe(false);
  });
});

describe("createToolRequest (US-WEB-04, unchanged)", () => {
  it("still files a plain tool request", async () => {
    fetchMock.mockResolvedValue(json({ ticket: { id: ID } }, 201));
    const result = await createToolRequest("tok", "Tool request: X", "We use it.");
    expect(result.ok && result.value).toEqual({ id: ID });
    expect(JSON.parse(String(fetchMock.mock.calls[0]![1]?.body))).toMatchObject({
      category: "tool_request",
    });
  });
});
