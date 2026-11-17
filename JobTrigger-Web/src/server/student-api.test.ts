// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { failureFor } from "./backend-client";
import {
  confirmStudentEmail,
  getStudent,
  startStudentEmail,
  uploadStudentDocument,
} from "./student-api";

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

const sent = (index = 0) => {
  const [url, init] = fetchMock.mock.calls[index]!;
  return { url: String(url), init: init!, body: JSON.parse(String(init!.body ?? "null")) };
};

describe("getStudent", () => {
  it("maps the application and fills missing fields", async () => {
    fetchMock.mockResolvedValue(json({ status: "pending", method: "document" }));
    const result = await getStudent("tok");
    expect(result).toEqual({
      ok: true,
      value: {
        status: "pending",
        method: "document",
        universityEmail: null,
        rejectionReason: null,
        approvedAt: null,
        expiresAt: null,
      },
    });
    expect(sent().url).toBe("http://backend.test/api/student");
    expect((sent().init.headers as Record<string, string>)["x-auth-token"]).toBe("tok");
  });

  it("reads none, and an unknown status as none", async () => {
    fetchMock.mockResolvedValue(json({ status: "none" }));
    expect((await getStudent("t")).ok && (await getStudent("t"))).toBeTruthy();
    fetchMock.mockResolvedValue(json({ status: "from-the-future" }));
    const result = await getStudent("t");
    expect(result.ok && result.value.status).toBe("none");
  });
});

describe("startStudentEmail", () => {
  it("posts the university email", async () => {
    fetchMock.mockResolvedValue(json({ message: "sent", expiresInMinutes: 10 }, 202));
    expect(await startStudentEmail("tok", "a@uom.ac.lk")).toEqual({ ok: true, value: null });
    expect(sent().url).toBe("http://backend.test/api/student/email/start");
    expect(sent().body).toEqual({ universityEmail: "a@uom.ac.lk" });
  });

  it("keeps the code of an unlisted domain", async () => {
    fetchMock.mockResolvedValue(
      json({ code: "domain_not_listed", message: "Upload a student ID instead." }, 400),
    );
    expect(await startStudentEmail("tok", "a@gmail.com")).toEqual({
      ok: false,
      failure: {
        kind: "explained",
        status: 400,
        code: "domain_not_listed",
        message: "Upload a student ID instead.",
      },
    });
  });

  it("shows the backend's sentence for 409, 413, 415, 429 and 503", async () => {
    for (const status of [409, 413, 415, 429, 503]) {
      fetchMock.mockResolvedValue(json({ message: `Sentence ${status}` }, status));
      const result = await startStudentEmail("tok", "a@uom.ac.lk");
      expect(result).toMatchObject({
        ok: false,
        failure: { kind: "explained", status, message: `Sentence ${status}` },
      });
    }
  });

  it("maps 401 and 5xx as every other call does", async () => {
    fetchMock.mockResolvedValue(json({ message: "no" }, 401));
    expect(await startStudentEmail("tok", "a@uom.ac.lk")).toEqual({
      ok: false,
      failure: { kind: "auth" },
    });
    fetchMock.mockResolvedValue(json({ message: "boom" }, 500));
    const result = await startStudentEmail("tok", "a@uom.ac.lk");
    expect(result).toMatchObject({ ok: false, failure: { kind: "server", status: 500 } });
  });
});

describe("confirm and upload", () => {
  it("confirm posts the code and parses the approved year", async () => {
    fetchMock.mockResolvedValue(
      json({ status: "approved", method: "email", expiresAt: "2027-11-16T00:00:00.000Z" }),
    );
    const result = await confirmStudentEmail("tok", "123456");
    expect(result.ok && result.value.status).toBe("approved");
    expect(sent().body).toEqual({ code: "123456" });
  });

  it("upload posts the name and the file as base64", async () => {
    fetchMock.mockResolvedValue(json({ status: "pending", method: "document" }, 201));
    const result = await uploadStudentDocument("tok", "Kasun Perera", "QUJD");
    expect(result.ok && result.value.status).toBe("pending");
    expect(sent().url).toBe("http://backend.test/api/student/document");
    expect(sent().body).toEqual({ fullName: "Kasun Perera", data: "QUJD" });
  });
});

describe("other calls are unchanged", () => {
  it("a 409 or 413 without the opt-in is still a plain server failure", () => {
    expect(failureFor(409, { message: "x" }, null)).toEqual({ kind: "server", status: 409 });
    expect(failureFor(413, { message: "x" }, null)).toEqual({ kind: "server", status: 413 });
    expect(failureFor(503, { message: "x" }, null)).toEqual({ kind: "billingUnavailable" });
  });
});
