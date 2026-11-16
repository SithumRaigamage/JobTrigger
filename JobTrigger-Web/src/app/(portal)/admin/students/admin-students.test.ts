// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const listStudents = vi.fn();
const getStudentApplication = vi.fn();
const fetchStudentDocument = vi.fn();
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
vi.mock("@/server/admin-students-api", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/server/admin-students-api")>()),
  listStudents: (...args: unknown[]) => listStudents(...args),
  getStudentApplication: (...args: unknown[]) => getStudentApplication(...args),
  fetchStudentDocument: (...args: unknown[]) => fetchStudentDocument(...args),
}));

import AdminStudentPage from "./[id]/page";
import { GET as getDocument } from "./[id]/document/route";
import AdminStudentsPage from "./page";

const ID = "64b0000000000000000000aa";
const params = (value: Record<string, string>) => Promise.resolve(value);

beforeEach(() => {
  for (const mock of [
    listStudents,
    getStudentApplication,
    fetchStudentDocument,
    getSession,
    notFound,
  ]) {
    mock.mockReset();
  }
  notFound.mockImplementation(() => {
    throw new Error("NOT_FOUND");
  });
});

describe("the queue page", () => {
  const props = (search: Record<string, string> = {}) =>
    ({ searchParams: params(search) }) as never;

  it("is a 404 page for a non-admin (the backend's plain 404)", async () => {
    listStudents.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    await expect(AdminStudentsPage(props())).rejects.toThrow("NOT_FOUND");
  });

  it("asks for pending by default and ignores an unknown status", async () => {
    listStudents.mockResolvedValue({ ok: true, value: [] });
    await AdminStudentsPage(props({ status: "evil" }));
    expect(listStudents).toHaveBeenCalledWith("a", { status: "pending", q: "" });
    await AdminStudentsPage(props({ status: "approved", q: " kasun " }));
    expect(listStudents).toHaveBeenLastCalledWith("a", { status: "approved", q: "kasun" });
  });

  it("an unreachable backend is shown as an error, not a 404", async () => {
    listStudents.mockResolvedValue({ ok: false, failure: { kind: "network" } });
    await expect(AdminStudentsPage(props())).resolves.toBeTruthy();
    expect(notFound).not.toHaveBeenCalled();
  });
});

describe("the application page", () => {
  it("is a 404 for a bad id without calling the backend", async () => {
    await expect(AdminStudentPage({ params: params({ id: "../x" }) } as never)).rejects.toThrow(
      "NOT_FOUND",
    );
    expect(getStudentApplication).not.toHaveBeenCalled();
  });

  it("is a 404 for a non-admin or a missing application", async () => {
    getStudentApplication.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    await expect(AdminStudentPage({ params: params({ id: ID }) } as never)).rejects.toThrow(
      "NOT_FOUND",
    );
  });
});

describe("the document route", () => {
  const call = (id = ID) =>
    getDocument(new Request("http://x"), { params: params({ id }) } as never);

  it("is a plain 404 with no session", async () => {
    getSession.mockResolvedValue({});
    const response = await call();
    expect(response.status).toBe(404);
    expect(fetchStudentDocument).not.toHaveBeenCalled();
  });

  it("is a plain 404 for a bad id and for a non-admin", async () => {
    getSession.mockResolvedValue({ accessToken: "a" });
    expect((await call("../../etc")).status).toBe(404);
    fetchStudentDocument.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    expect((await call()).status).toBe(404);
  });

  it("streams an image inline with no-store, nosniff and a sandbox", async () => {
    getSession.mockResolvedValue({ accessToken: "a" });
    fetchStudentDocument.mockResolvedValue({
      ok: true,
      value: { bytes: new Uint8Array([1, 2, 3]).buffer, contentType: "image/png" },
    });
    const response = await call();
    expect(response.status).toBe(200);
    expect(response.headers.get("content-type")).toBe("image/png");
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
    expect(response.headers.get("content-security-policy")).toContain("sandbox");
    expect(response.headers.get("content-disposition")).toContain("inline");
    expect(new Uint8Array(await response.arrayBuffer())).toEqual(new Uint8Array([1, 2, 3]));
  });

  it("a PDF is a download, and an odd type is never served as itself", async () => {
    getSession.mockResolvedValue({ accessToken: "a" });
    fetchStudentDocument.mockResolvedValue({
      ok: true,
      value: { bytes: new Uint8Array([1]).buffer, contentType: "application/pdf" },
    });
    const pdf = await call();
    expect(pdf.headers.get("content-disposition")).toContain("attachment");

    fetchStudentDocument.mockResolvedValue({
      ok: true,
      value: { bytes: new Uint8Array([1]).buffer, contentType: "text/html" },
    });
    const odd = await call();
    expect(odd.headers.get("content-type")).toBe("application/pdf");
    expect(odd.headers.get("content-disposition")).toContain("attachment");
  });

  it("a deleted document is a 410", async () => {
    getSession.mockResolvedValue({ accessToken: "a" });
    fetchStudentDocument.mockResolvedValue({
      ok: false,
      failure: { kind: "explained", status: 410, message: "gone" },
    });
    expect((await call()).status).toBe(410);
  });
});
