import { render, screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminStudent } from "@/domain/student";

vi.mock("./actions", () => ({
  approveStudentAction: vi.fn(async () => ({})),
  rejectStudentAction: vi.fn(async () => ({})),
}));

import { StudentDetailView, StudentsView } from "./students-view";

const base: AdminStudent = {
  id: "64b0000000000000000000aa",
  userId: "u1",
  accountEmail: "kasun@example.com",
  method: "document",
  status: "pending",
  fullName: "Kasun Perera",
  universityEmail: null,
  submittedAt: "2026-11-16T10:00:00.000Z",
  reviewedAt: null,
  approvedAt: null,
  expiresAt: null,
  rejectionReason: null,
  documentMime: "image/png",
  documentSize: 1000,
  hasDocument: true,
  documentDeleted: false,
  documentDeleteAt: null,
};

describe("StudentsView", () => {
  it("lists applications with the name, account and a Review link", () => {
    render(<StudentsView items={[base]} failure={null} status="pending" q="" />);
    expect(screen.getByRole("heading", { name: "Student applications", level: 1 })).toBeVisible();
    expect(screen.getByText("Kasun Perera")).toBeVisible();
    expect(screen.getByText("kasun@example.com")).toBeVisible();
    expect(screen.getByRole("link", { name: "Review" })).toHaveAttribute(
      "href",
      `/admin/students/${base.id}`,
    );
    // The document is never in the list.
    expect(document.querySelector("img")).toBeNull();
  });

  it("marks the chosen filter and keeps the search in the other links", () => {
    render(<StudentsView items={[]} failure={null} status="approved" q="kasun" />);
    const nav = screen.getByRole("navigation", { name: "Status" });
    expect(within(nav).getByRole("link", { name: "Approved" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(within(nav).getByRole("link", { name: "Pending" })).toHaveAttribute(
      "href",
      "/admin/students?status=pending&q=kasun",
    );
    expect(screen.getByRole("searchbox", { name: /Search by exact account email/ })).toHaveValue(
      "kasun",
    );
    expect(screen.getByText("No applications here.")).toBeVisible();
  });

  it("shows a failure instead of the list", () => {
    render(<StudentsView items={[]} failure={{ kind: "network" }} status="pending" q="" />);
    expect(screen.getByRole("alert")).toHaveTextContent("Can't reach the server");
  });

  it("confirms a decision after redirecting back", () => {
    render(<StudentsView items={[]} failure={null} status="pending" q="" notice="approved" />);
    expect(screen.getByRole("status")).toHaveTextContent(
      "Approved. The student has Pro for 365 days.",
    );
  });

  it("shows a deleted name and account plainly", () => {
    render(
      <StudentsView
        items={[{ ...base, fullName: null, accountEmail: null }]}
        failure={null}
        status="all"
        q=""
      />,
    );
    expect(screen.getByText("(name deleted)")).toBeVisible();
    expect(screen.getByText("(account deleted)")).toBeVisible();
  });
});

describe("StudentDetailView", () => {
  it("shows an image from our own route and the approve and reject forms when pending", () => {
    render(<StudentDetailView item={base} />);
    expect(screen.getByText("Kasun Perera")).toBeVisible();
    expect(screen.getByRole("img", { name: /uploaded document/ })).toHaveAttribute(
      "src",
      `/admin/students/${base.id}/document`,
    );
    expect(screen.getByRole("button", { name: "Approve" })).toBeVisible();
    expect(screen.getByRole("button", { name: "Reject" })).toBeVisible();
    expect(screen.getByLabelText(/Reason/)).toBeRequired();
  });

  it("a PDF is a download link, not an embedded viewer", () => {
    render(<StudentDetailView item={{ ...base, documentMime: "application/pdf" }} />);
    expect(screen.queryByRole("img")).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Download the PDF" })).toHaveAttribute(
      "href",
      `/admin/students/${base.id}/document`,
    );
    expect(document.querySelector("iframe, object, embed")).toBeNull();
  });

  it("a decided application has no decision forms", () => {
    render(
      <StudentDetailView
        item={{
          ...base,
          status: "rejected",
          rejectionReason: "Blurry",
          reviewedAt: "2026-11-17T10:00:00.000Z",
          documentDeleteAt: "2026-12-17T10:00:00.000Z",
        }}
      />,
    );
    expect(screen.getByText("Blurry")).toBeVisible();
    expect(screen.getByText("December 17, 2026")).toBeVisible();
    expect(screen.queryByRole("button", { name: "Approve" })).not.toBeInTheDocument();
  });

  it("after the 30 days it says the file and name are gone", () => {
    render(
      <StudentDetailView
        item={{
          ...base,
          status: "approved",
          fullName: null,
          hasDocument: false,
          documentDeleted: true,
        }}
      />,
    );
    expect(screen.getByText(/Deleted 30 days after the decision/)).toBeVisible();
    expect(screen.queryByRole("img")).not.toBeInTheDocument();
    expect(screen.getByText("(deleted)")).toBeVisible();
  });

  it("an email-verified application has no document and no forms", () => {
    render(
      <StudentDetailView
        item={{
          ...base,
          method: "email",
          status: "approved",
          hasDocument: false,
          documentMime: null,
        }}
      />,
    );
    expect(screen.getByText("No document.")).toBeVisible();
    expect(screen.queryByRole("button", { name: "Approve" })).not.toBeInTheDocument();
  });
});
