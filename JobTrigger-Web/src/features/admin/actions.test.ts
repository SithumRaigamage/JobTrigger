// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const approveStudent = vi.fn();
const rejectStudent = vi.fn();
const updateSupportStatus = vi.fn();
const redirect = vi.fn((url: string) => {
  throw new Error(`REDIRECT ${url}`);
});

vi.mock("next/cache", () => ({ revalidatePath: vi.fn() }));
vi.mock("next/navigation", () => ({ redirect: (url: string) => redirect(url) }));
vi.mock("@/server/guard", () => ({ requireSession: async () => ({ accessToken: "a" }) }));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/admin-students-api", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/server/admin-students-api")>()),
  approveStudent: (...args: unknown[]) => approveStudent(...args),
  rejectStudent: (...args: unknown[]) => rejectStudent(...args),
}));
vi.mock("@/server/support-api", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/server/support-api")>()),
  updateSupportStatus: (...args: unknown[]) => updateSupportStatus(...args),
}));

import { approveStudentAction, rejectStudentAction, updateSupportStatusAction } from "./actions";

const ID = "64b0000000000000000000aa";
const form = (values: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(values)) data.set(key, value);
  return data;
};

beforeEach(() => {
  approveStudent.mockReset();
  rejectStudent.mockReset();
  updateSupportStatus.mockReset();
  redirect.mockClear();
});

describe("approveStudentAction", () => {
  it("refuses an id of the wrong shape before calling the backend", async () => {
    const state = await approveStudentAction({}, form({ id: "../../x" }));
    expect(state.error).toBe("That application couldn't be found.");
    expect(approveStudent).not.toHaveBeenCalled();
  });

  it("approves and goes back to the queue with a notice", async () => {
    approveStudent.mockResolvedValue({ ok: true, value: {} });
    await expect(approveStudentAction({}, form({ id: ID }))).rejects.toThrow(
      "REDIRECT /admin/students?notice=approved",
    );
    expect(approveStudent).toHaveBeenCalledWith("access-1", ID);
  });

  it("shows the backend's sentence on a conflict", async () => {
    approveStudent.mockResolvedValue({
      ok: false,
      failure: { kind: "explained", status: 409, message: "Already decided." },
    });
    expect((await approveStudentAction({}, form({ id: ID }))).error).toBe("Already decided.");
    expect(redirect).not.toHaveBeenCalled();
  });

  it("a non-admin gets the not-found message, nothing else", async () => {
    approveStudent.mockResolvedValue({ ok: false, failure: { kind: "notFound" } });
    expect((await approveStudentAction({}, form({ id: ID }))).error).toBe(
      "That couldn't be found — it may have been removed.",
    );
  });
});

describe("rejectStudentAction", () => {
  it("needs a reason, within 500 characters", async () => {
    expect((await rejectStudentAction({}, form({ id: ID, reason: "  " }))).error).toBe(
      "Give a reason. The student sees it.",
    );
    expect(
      (await rejectStudentAction({}, form({ id: ID, reason: "x".repeat(501) }))).error,
    ).toMatch(/under 500/);
    expect(rejectStudent).not.toHaveBeenCalled();
  });

  it("rejects with the trimmed reason and goes back to the queue", async () => {
    rejectStudent.mockResolvedValue({ ok: true, value: {} });
    await expect(
      rejectStudentAction({}, form({ id: ID, reason: "  Too blurry " })),
    ).rejects.toThrow("REDIRECT /admin/students?notice=rejected");
    expect(rejectStudent).toHaveBeenCalledWith("access-1", ID, "Too blurry");
  });

  it("refuses a bad id", async () => {
    expect((await rejectStudentAction({}, form({ id: "nope", reason: "r" }))).error).toBe(
      "That application couldn't be found.",
    );
  });
});

// US-SUP-07: the same triage control, now on a support ticket.
describe("updateSupportStatusAction", () => {
  it("refuses a bad id or an unknown status before calling the backend", async () => {
    expect((await updateSupportStatusAction({}, form({ id: "../x", status: "open" }))).error).toBe(
      "That report couldn't be found.",
    );
    expect((await updateSupportStatusAction({}, form({ id: ID, status: "evil" }))).error).toBe(
      "Choose a known status.",
    );
    expect(updateSupportStatus).not.toHaveBeenCalled();
  });

  it("moves the ticket and reports the new status", async () => {
    updateSupportStatus.mockResolvedValue({ ok: true, value: {} });
    const state = await updateSupportStatusAction({}, form({ id: ID, status: "closed" }));
    expect(updateSupportStatus).toHaveBeenCalledWith("access-1", ID, "closed");
    expect(state).toEqual({ notice: "Marked closed." });
  });

  it("shows the backend's failure", async () => {
    updateSupportStatus.mockResolvedValue({ ok: false, failure: { kind: "network" } });
    const state = await updateSupportStatusAction({}, form({ id: ID, status: "triaged" }));
    expect(state.error).toMatch(/Can't reach the server/);
  });
});
