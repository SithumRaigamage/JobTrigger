// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from "vitest";

const startStudentEmail = vi.fn();
const confirmStudentEmail = vi.fn();
const uploadStudentDocument = vi.fn();
const revalidatePath = vi.fn();

vi.mock("next/cache", () => ({ revalidatePath: (...args: unknown[]) => revalidatePath(...args) }));
vi.mock("@/server/guard", () => ({ requireSession: async () => ({ accessToken: "a" }) }));
vi.mock("@/server/authed", () => ({
  authed: async (_session: unknown, call: (token: string) => unknown) => call("access-1"),
}));
vi.mock("@/server/student-api", () => ({
  startStudentEmail: (...args: unknown[]) => startStudentEmail(...args),
  confirmStudentEmail: (...args: unknown[]) => confirmStudentEmail(...args),
  uploadStudentDocument: (...args: unknown[]) => uploadStudentDocument(...args),
}));

import {
  confirmStudentCodeAction,
  resendStudentCodeAction,
  startStudentEmailAction,
  uploadStudentDocumentAction,
} from "./actions";

beforeEach(() => {
  for (const mock of [
    startStudentEmail,
    confirmStudentEmail,
    uploadStudentDocument,
    revalidatePath,
  ]) {
    mock.mockReset();
  }
});

const form = (values: Record<string, string | File>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(values)) data.set(key, value);
  return data;
};
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]);
const approved = {
  ok: true,
  value: { status: "approved", method: "email" },
};

describe("startStudentEmailAction", () => {
  it("refuses a malformed email without calling the backend", async () => {
    const state = await startStudentEmailAction({}, form({ email: "nope" }));
    expect(state.error).toBe("Enter your university email address.");
    expect(startStudentEmail).not.toHaveBeenCalled();
  });

  it("moves to the code step with the trimmed email", async () => {
    startStudentEmail.mockResolvedValue({ ok: true, value: null });
    const state = await startStudentEmailAction({}, form({ email: "  a@uom.ac.lk " }));
    expect(startStudentEmail).toHaveBeenCalledWith("access-1", "a@uom.ac.lk");
    expect(state).toEqual({ step: { step: "code", email: "a@uom.ac.lk" } });
  });

  it("an unlisted domain moves to the document step", async () => {
    startStudentEmail.mockResolvedValue({
      ok: false,
      failure: { kind: "explained", status: 400, code: "domain_not_listed", message: "x" },
    });
    const state = await startStudentEmailAction({}, form({ email: "a@gmail.com" }));
    expect(state).toEqual({ step: { step: "document", domainNotListed: true } });
  });

  it("any other failure shows the backend's sentence", async () => {
    startStudentEmail.mockResolvedValue({
      ok: false,
      failure: { kind: "explained", status: 409, code: "email_used", message: "Already used." },
    });
    expect((await startStudentEmailAction({}, form({ email: "a@uom.ac.lk" }))).error).toBe(
      "Already used.",
    );
  });

  it("resend sends again to the same email", async () => {
    startStudentEmail.mockResolvedValue({ ok: true, value: null });
    expect(await resendStudentCodeAction(" a@uom.ac.lk ")).toEqual({
      step: { step: "code", email: "a@uom.ac.lk" },
    });
  });
});

describe("confirmStudentCodeAction", () => {
  it("refuses anything but 6 digits", async () => {
    for (const code of ["", "12345", "1234567", "12ab56"]) {
      expect((await confirmStudentCodeAction({}, form({ code }))).error).toBe(
        "Enter the 6-digit code.",
      );
    }
    expect(confirmStudentEmail).not.toHaveBeenCalled();
  });

  it("the right code is done, and refreshes the account page", async () => {
    confirmStudentEmail.mockResolvedValue(approved);
    expect(await confirmStudentCodeAction({}, form({ code: " 123456 " }))).toEqual({ done: true });
    expect(confirmStudentEmail).toHaveBeenCalledWith("access-1", "123456");
    expect(revalidatePath).toHaveBeenCalledWith("/account");
  });

  it("a wrong code shows the backend's sentence and does not refresh", async () => {
    confirmStudentEmail.mockResolvedValue({
      ok: false,
      failure: { kind: "explained", status: 400, code: "wrong_code", message: "4 tries left." },
    });
    expect((await confirmStudentCodeAction({}, form({ code: "000000" }))).error).toBe(
      "4 tries left.",
    );
    expect(revalidatePath).not.toHaveBeenCalled();
  });
});

describe("uploadStudentDocumentAction", () => {
  const png = (name = "id.png") => new File([PNG], name, { type: "image/png" });

  it("needs the full name", async () => {
    for (const fullName of ["", " ", "A", "x".repeat(101)]) {
      const state = await uploadStudentDocumentAction({}, form({ fullName, file: png() }));
      expect(state.error).toBe("Enter your full name as it appears on your student ID.");
    }
    expect(uploadStudentDocument).not.toHaveBeenCalled();
  });

  it("needs a file", async () => {
    expect((await uploadStudentDocumentAction({}, form({ fullName: "Kasun Perera" }))).error).toBe(
      "Choose a file to upload.",
    );
  });

  it("refuses the wrong type by name and by content, and an empty file", async () => {
    const byName = await uploadStudentDocumentAction(
      {},
      form({ fullName: "Kasun Perera", file: new File([PNG], "notes.txt") }),
    );
    expect(byName.error).toBe("Only JPG, PNG or PDF files are accepted");

    const byContent = await uploadStudentDocumentAction(
      {},
      form({ fullName: "Kasun Perera", file: new File(["<html>"], "id.png") }),
    );
    expect(byContent.error).toBe("Only JPG, PNG or PDF files are accepted");

    const empty = await uploadStudentDocumentAction(
      {},
      form({ fullName: "Kasun Perera", file: new File([], "id.png") }),
    );
    expect(empty.error).toBe("That file is empty. Choose another.");
    expect(uploadStudentDocument).not.toHaveBeenCalled();
  });

  it("refuses a file over 5 MB with the agreed message", async () => {
    const big = new File([new Uint8Array(5 * 1024 * 1024 + 1)], "big.pdf");
    const state = await uploadStudentDocumentAction(
      {},
      form({ fullName: "Kasun Perera", file: big }),
    );
    expect(state.error).toBe("File too large, max 5 MB");
    expect(uploadStudentDocument).not.toHaveBeenCalled();
  });

  it("sends the tidied name and the file as base64, then refreshes", async () => {
    uploadStudentDocument.mockResolvedValue({ ok: true, value: { status: "pending" } });
    const state = await uploadStudentDocumentAction(
      {},
      form({ fullName: "  Kasun   Perera ", file: png() }),
    );
    expect(state).toEqual({ done: true });
    expect(uploadStudentDocument).toHaveBeenCalledWith(
      "access-1",
      "Kasun Perera",
      Buffer.from(PNG).toString("base64"),
    );
    expect(revalidatePath).toHaveBeenCalledWith("/account");
  });

  it("shows the backend's sentence when it refuses", async () => {
    uploadStudentDocument.mockResolvedValue({
      ok: false,
      failure: {
        kind: "explained",
        status: 409,
        code: "under_review",
        message: "Already waiting.",
      },
    });
    const state = await uploadStudentDocumentAction(
      {},
      form({ fullName: "Kasun Perera", file: png() }),
    );
    expect(state.error).toBe("Already waiting.");
    expect(revalidatePath).not.toHaveBeenCalled();
  });
});
