// @vitest-environment node
import { describe, expect, it } from "vitest";

import {
  STUDENT_MAX_BYTES,
  checkDocumentFile,
  checkDocumentMeta,
  documentProblemMessage,
  looksLikeStudentDocument,
  studentAt,
  tidyName,
  type StudentApplication,
} from "./student";

const PNG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2];
const file = (name: string, bytes: number[] | string, size?: number) => {
  const blob = new File([typeof bytes === "string" ? bytes : new Uint8Array(bytes)], name);
  return size === undefined ? blob : Object.defineProperty(blob, "size", { value: size });
};

describe("checkDocumentMeta", () => {
  it("accepts JPG, JPEG, PNG and PDF in any case", () => {
    for (const name of ["id.jpg", "ID.JPEG", "scan.png", "letter.PDF"]) {
      expect(checkDocumentMeta(name, 100)).toBeNull();
    }
  });

  it("refuses other types and names with no extension", () => {
    for (const name of ["id.gif", "a.exe", "noext", "x.png.exe", "id.heic"]) {
      expect(checkDocumentMeta(name, 100), name).toBe("wrongType");
    }
  });

  it("allows exactly 5 MB and refuses one byte more", () => {
    expect(checkDocumentMeta("a.pdf", STUDENT_MAX_BYTES)).toBeNull();
    expect(checkDocumentMeta("a.pdf", STUDENT_MAX_BYTES + 1)).toBe("tooLarge");
  });

  it("refuses an empty file", () => {
    expect(checkDocumentMeta("a.png", 0)).toBe("empty");
  });

  it("uses the agreed copy", () => {
    expect(documentProblemMessage("tooLarge")).toBe("File too large, max 5 MB");
    expect(documentProblemMessage("wrongType")).toBe("Only JPG, PNG or PDF files are accepted");
  });
});

describe("looksLikeStudentDocument", () => {
  it("recognises JPG, PNG and PDF by their first bytes", () => {
    expect(looksLikeStudentDocument(new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1]))).toBe(true);
    expect(looksLikeStudentDocument(new Uint8Array(PNG))).toBe(true);
    expect(looksLikeStudentDocument(new TextEncoder().encode("%PDF-1.7 x"))).toBe(true);
  });

  it("refuses everything else, whatever the name says", () => {
    expect(looksLikeStudentDocument(new TextEncoder().encode("<html>"))).toBe(false);
    expect(looksLikeStudentDocument(new Uint8Array())).toBe(false);
    expect(looksLikeStudentDocument(new Uint8Array([0xff, 0xd8]))).toBe(false);
  });
});

describe("checkDocumentFile", () => {
  it("passes a real PNG", async () => {
    expect(await checkDocumentFile(file("id.png", PNG))).toBeNull();
  });

  it("refuses a text file named .png", async () => {
    expect(await checkDocumentFile(file("id.png", "not an image"))).toBe("wrongType");
  });

  it("refuses by name and size before reading anything", async () => {
    expect(await checkDocumentFile(file("notes.txt", PNG))).toBe("wrongType");
    expect(await checkDocumentFile(file("big.pdf", PNG, STUDENT_MAX_BYTES + 1))).toBe("tooLarge");
  });
});

describe("studentAt and tidyName", () => {
  const approved: StudentApplication = {
    status: "approved",
    method: "email",
    universityEmail: null,
    rejectionReason: null,
    approvedAt: null,
    expiresAt: "2027-01-01T00:00:00.000Z",
  };

  it("an approved year past its end reads as expired", () => {
    expect(studentAt(approved, new Date("2027-01-02")).status).toBe("expired");
    expect(studentAt(approved, new Date("2026-12-31")).status).toBe("approved");
  });

  it("other statuses are unchanged", () => {
    const pending = { ...approved, status: "pending" as const };
    expect(studentAt(pending, new Date("2030-01-01"))).toBe(pending);
  });

  it("tidies the name", () => {
    expect(tidyName("  Kasun   \t Perera ")).toBe("Kasun Perera");
  });
});
