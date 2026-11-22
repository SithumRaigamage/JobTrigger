import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { StudentApplication } from "@/domain/student";
import { AccountView } from "@/features/account/account-view";
import type { Subscription } from "@/domain/subscription";

vi.mock("./actions", () => ({
  startStudentEmailAction: vi.fn(async () => ({ step: { step: "code", email: "a@uom.ac.lk" } })),
  resendStudentCodeAction: vi.fn(async () => ({ step: { step: "code", email: "a@uom.ac.lk" } })),
  confirmStudentCodeAction: vi.fn(async () => ({ done: true })),
  uploadStudentDocumentAction: vi.fn(async () => ({ done: true })),
}));

import { StudentCard } from "./student-card";

const none: StudentApplication = {
  status: "none",
  method: null,
  universityEmail: null,
  rejectionReason: null,
  approvedAt: null,
  expiresAt: null,
};
const as = (patch: Partial<StudentApplication>): StudentApplication => ({ ...none, ...patch });

const free: Subscription = {
  plan: "free",
  billingEnabled: true,
  state: "none",
  source: null,
  periodEnd: null,
  willRenew: false,
  manageOnWeb: false,
  limits: { maxCredentialsTotal: 1, maxCredentialsPerTool: 1, maxPinnedJobs: 3 },
  features: { multiTool: false, backgroundWatch: false, homeWidget: false, insights: false },
};

describe("StudentCard", () => {
  it("no application: asks for the university email and offers the document", () => {
    render(<StudentCard application={none} />);
    expect(screen.getByRole("heading", { name: "Student verification" })).toBeVisible();
    expect(screen.getByLabelText("University email")).toBeVisible();
    expect(screen.getByRole("button", { name: "Send code" })).toBeVisible();
    expect(screen.getByRole("button", { name: /Upload a student ID/ })).toBeVisible();
  });

  it("pending review", () => {
    render(<StudentCard application={as({ status: "pending", method: "document" })} />);
    expect(screen.getByText("Pending review")).toBeVisible();
    expect(screen.queryByLabelText("University email")).not.toBeInTheDocument();
  });

  it("pending review of a verified university email says so (US-STU-01)", () => {
    render(<StudentCard application={as({ status: "pending", method: "email" })} />);
    expect(screen.getByText("Pending review")).toBeVisible();
    expect(screen.getByText(/Your university email is verified/)).toBeVisible();
    expect(screen.queryByText(/student document/)).not.toBeInTheDocument();
  });

  it("a rejected email application shows the reason with Try again (US-STU-01)", () => {
    render(
      <StudentCard
        application={as({
          status: "rejected",
          method: "email",
          rejectionReason: "Not a student address",
        })}
      />,
    );
    expect(screen.getByText(/We couldn't approve your application/)).toBeVisible();
    expect(screen.getByText(/Not a student address/)).toBeVisible();
    fireEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(screen.getByLabelText("University email")).toBeVisible();
  });

  it("approved shows the end date", () => {
    render(
      <StudentCard
        application={as({ status: "approved", expiresAt: "2027-11-16T10:00:00.000Z" })}
      />,
    );
    expect(screen.getByRole("status")).toHaveTextContent(
      "You have JobTrigger Pro as a student, free until November 16, 2027.",
    );
  });

  it("ended: one year per person, back on Free", () => {
    render(<StudentCard application={as({ status: "expired" })} />);
    expect(screen.getByText(/Your student year has ended/)).toBeVisible();
    expect(screen.queryByLabelText("University email")).not.toBeInTheDocument();
  });

  it("rejected shows the reason, and Try again reopens the form", () => {
    render(
      <StudentCard
        application={as({
          status: "rejected",
          method: "document",
          rejectionReason: "The photo is too blurry to read.",
        })}
      />,
    );
    expect(screen.getByText(/The photo is too blurry to read\./)).toBeVisible();
    fireEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(screen.getByLabelText("University email")).toBeVisible();
  });

  it("the document step asks for the full name and the file, with the limits", () => {
    render(<StudentCard application={none} />);
    fireEvent.click(screen.getByRole("button", { name: /Upload a student ID/ }));
    expect(screen.getByLabelText("Full name as on your student ID")).toBeVisible();
    const input = screen.getByLabelText("Student ID or enrolment letter") as HTMLInputElement;
    expect(input).toHaveAttribute("type", "file");
    expect(input.accept).toContain(".pdf");
    expect(screen.getByText(/JPG, PNG or PDF, up to 5 MB/)).toBeVisible();
    expect(screen.getByText(/delete the file 30 days after we decide/)).toBeVisible();
  });

  it("a file of the wrong type is refused in the browser and not shown as chosen", async () => {
    render(<StudentCard application={none} />);
    fireEvent.click(screen.getByRole("button", { name: /Upload a student ID/ }));
    const input = screen.getByLabelText("Student ID or enrolment letter") as HTMLInputElement;
    fireEvent.change(input, {
      target: { files: [new File(["hello"], "notes.txt", { type: "text/plain" })] },
    });
    expect(await screen.findByText("Only JPG, PNG or PDF files are accepted")).toBeVisible();
    expect(screen.queryByText(/Selected:/)).not.toBeInTheDocument();
  });

  it("a real PNG is accepted and named", async () => {
    render(<StudentCard application={none} />);
    fireEvent.click(screen.getByRole("button", { name: /Upload a student ID/ }));
    const png = new File(
      [new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2])],
      "id.png",
      { type: "image/png" },
    );
    fireEvent.change(screen.getByLabelText("Student ID or enrolment letter"), {
      target: { files: [png] },
    });
    expect(await screen.findByText("Selected: id.png")).toBeVisible();
    expect(screen.queryByText("Only JPG, PNG or PDF files are accepted")).not.toBeInTheDocument();
  });

  it("sending the email moves to the code step", async () => {
    render(<StudentCard application={none} />);
    fireEvent.change(screen.getByLabelText("University email"), {
      target: { value: "a@uom.ac.lk" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Send code" }));
    expect(await screen.findByText(/We sent a 6-digit code to/)).toBeVisible();
    expect(screen.getByLabelText("Code")).toBeVisible();
    expect(screen.getByRole("button", { name: "Send a new code" })).toBeVisible();
  });
});

describe("Account page", () => {
  it("shows the student card only when it is given one", () => {
    const { rerender } = render(<AccountView email="a@b.dev" subscription={free} student={none} />);
    expect(screen.getByRole("heading", { name: "Student verification" })).toBeVisible();
    rerender(<AccountView email="a@b.dev" subscription={free} student={null} />);
    expect(screen.queryByRole("heading", { name: "Student verification" })).not.toBeInTheDocument();
  });

  it("never shows it with billing off (no subscription card)", () => {
    render(<AccountView email="a@b.dev" subscription={null} student={none} />);
    expect(screen.queryByRole("heading", { name: "Student verification" })).not.toBeInTheDocument();
  });

  it("names the student plan as the source of Pro", () => {
    render(
      <AccountView
        email="a@b.dev"
        subscription={{
          ...free,
          plan: "pro",
          state: "active",
          source: "student",
          periodEnd: "2027-11-16T10:00:00.000Z",
        }}
        student={as({ status: "approved", expiresAt: "2027-11-16T10:00:00.000Z" })}
      />,
    );
    expect(
      screen.getByText(/You're on Pro through the student plan\. It ends on November 16, 2027\./),
    ).toBeVisible();
  });
});
