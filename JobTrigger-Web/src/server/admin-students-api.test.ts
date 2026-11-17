// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { callBackendBytes } from "./backend-client";
import {
  approveStudent,
  fetchStudentDocument,
  getStudentApplication,
  isStudentId,
  listStudents,
  rejectStudent,
} from "./admin-students-api";

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
  userId: "u1",
  accountEmail: "a@b.dev",
  method: "document",
  status: "pending",
  fullName: "Kasun Perera",
  universityEmail: null,
  submittedAt: "2026-11-16T00:00:00.000Z",
  reviewedAt: null,
  approvedAt: null,
  expiresAt: null,
  rejectionReason: null,
  documentMime: "image/png",
  documentSize: 100,
  hasDocument: true,
  documentDeleted: false,
  documentDeleteAt: null,
};

describe("listStudents", () => {
  it("asks for the status and the search, and unwraps the items", async () => {
    fetchMock.mockResolvedValue(json({ items: [row] }));
    const result = await listStudents("tok", { status: "pending", q: "kasun & co" });
    expect(result.ok && result.value).toHaveLength(1);
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(String(url)).toBe(
      "http://backend.test/api/admin/students?status=pending&q=kasun+%26+co",
    );
    expect((init!.headers as Record<string, string>)["x-auth-token"]).toBe("tok");
  });

  it("leaves q out when empty", async () => {
    fetchMock.mockResolvedValue(json({ items: [] }));
    await listStudents("tok", { status: "all", q: "" });
    expect(String(fetchMock.mock.calls[0]![0])).toBe(
      "http://backend.test/api/admin/students?status=all",
    );
  });

  it("a non-admin's 404 is a notFound failure", async () => {
    fetchMock.mockResolvedValue(json({ message: "Not found" }, 404));
    expect(await listStudents("tok", { status: "pending", q: "" })).toEqual({
      ok: false,
      failure: { kind: "notFound" },
    });
  });
});

describe("one application", () => {
  it("get, approve and reject use the id and the right verbs", async () => {
    fetchMock.mockResolvedValue(json(row));
    await getStudentApplication("tok", ID);
    await approveStudent("tok", ID);
    await rejectStudent("tok", ID, "Too blurry");
    const calls = fetchMock.mock.calls.map(([url, init]) => [String(url), init!.method ?? "GET"]);
    expect(calls).toEqual([
      [`http://backend.test/api/admin/students/${ID}`, "GET"],
      [`http://backend.test/api/admin/students/${ID}/approve`, "POST"],
      [`http://backend.test/api/admin/students/${ID}/reject`, "POST"],
    ]);
    expect(JSON.parse(String(fetchMock.mock.calls[2]![1]!.body))).toEqual({ reason: "Too blurry" });
  });

  it("shows the backend's own sentence when a decision conflicts", async () => {
    fetchMock.mockResolvedValue(json({ message: "This application is already approved." }, 409));
    expect(await approveStudent("tok", ID)).toMatchObject({
      ok: false,
      failure: { kind: "explained", message: "This application is already approved." },
    });
  });

  it("only accepts the backend's id shape", () => {
    expect(isStudentId(ID)).toBe(true);
    for (const bad of ["", "../x", "abc", `${ID}/approve`, `${ID}?x=1`, "g".repeat(24)]) {
      expect(isStudentId(bad), bad).toBe(false);
    }
  });
});

describe("the document", () => {
  it("returns the bytes with their type", async () => {
    fetchMock.mockResolvedValue(
      new Response(new Uint8Array([1, 2, 3]), { headers: { "content-type": "image/png" } }),
    );
    const result = await fetchStudentDocument("tok", ID);
    expect(result.ok && result.value.contentType).toBe("image/png");
    expect(result.ok && result.value.bytes.byteLength).toBe(3);
    expect(String(fetchMock.mock.calls[0]![0])).toBe(
      `http://backend.test/api/admin/students/${ID}/document`,
    );
  });

  it("a deleted document is a 410 with the backend's sentence", async () => {
    fetchMock.mockResolvedValue(json({ message: "Deleted 30 days after." }, 410));
    expect(await fetchStudentDocument("tok", ID)).toEqual({
      ok: false,
      failure: { kind: "explained", status: 410, message: "Deleted 30 days after." },
    });
  });

  it("a non-admin's 404 and an expired session map as elsewhere", async () => {
    fetchMock.mockResolvedValue(json({ message: "Not found" }, 404));
    expect(
      await callBackendBytes({ path: `/api/admin/students/${ID}/document`, accessToken: "t" }),
    ).toEqual({
      ok: false,
      failure: { kind: "notFound" },
    });
    fetchMock.mockResolvedValue(json({ message: "no" }, 401));
    expect(await fetchStudentDocument("t", ID)).toEqual({ ok: false, failure: { kind: "auth" } });
  });

  it("an unreachable backend is a network failure", async () => {
    fetchMock.mockRejectedValue(new TypeError("fetch failed"));
    expect(await fetchStudentDocument("t", ID)).toEqual({
      ok: false,
      failure: { kind: "network" },
    });
  });
});
