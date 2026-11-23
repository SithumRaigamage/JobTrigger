import { render, screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import type { AdminSupportTicket } from "@/domain/support";

vi.mock("./support-status-form", () => ({
  SupportStatusForm: ({ status }: { status: string }) => <p>Status control: {status}</p>,
}));

import { SupportDetailView, SupportQueueView } from "./support-view";

const ID = "64b0000000000000000000aa";
const row: AdminSupportTicket = {
  id: ID,
  category: "bug",
  subject: "Blank log",
  message: "Nothing shows after 5 minutes.",
  areas: ["jenkins", "phone"],
  impact: "blocked",
  screenshotCount: 1,
  status: "open",
  createdAt: "2026-11-23T00:00:00.000Z",
  updatedAt: "2026-11-23T00:00:00.000Z",
  replyEmail: "sam@acme.dev",
  userEmail: "sam@acme.dev",
  appVersion: "1.1.0",
  buildNumber: "2",
  tool: "jenkins",
  platform: "ios",
  serverHost: "https://jenkins.acme.dev",
};

describe("SupportQueueView (US-SUP-07)", () => {
  it("lists the triage signals and the status filters", () => {
    render(<SupportQueueView items={[row]} failure={null} status="open" />);
    expect(screen.getByRole("heading", { name: "Support reports" })).toBeVisible();
    expect(screen.getByText("Blank log")).toBeVisible();
    expect(screen.getByText(/Bug · Jenkins, Phone\/app · Blocked/)).toBeVisible();
    expect(screen.getByText(/1 screenshot · Open/)).toBeVisible();
    const filters = screen.getByRole("navigation", { name: "Status" });
    for (const label of ["Open", "Triaged", "Closed", "All"]) {
      expect(within(filters).getByRole("link", { name: label })).toBeVisible();
    }
    expect(
      screen
        .getAllByRole("link", { name: "Open" })
        .some((link) => link.getAttribute("href") === `/admin/support/${ID}`),
    ).toBe(true);
  });

  it("shows a backend failure instead of an empty queue", () => {
    render(<SupportQueueView items={[]} failure={{ kind: "network" }} status="open" />);
    expect(screen.getByRole("alert")).toHaveTextContent("Can't reach the server");
    expect(screen.queryByText("No reports here.")).not.toBeInTheDocument();
  });
});

describe("SupportDetailView (US-SUP-06/07)", () => {
  it("shows the options, the message and a thumbnail linking to the full image", () => {
    const item: AdminSupportTicket = {
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
    render(<SupportDetailView item={item} />);
    expect(screen.getByText("Nothing shows after 5 minutes.")).toBeVisible();
    expect(screen.getByText("Jenkins, Phone/app")).toBeVisible();
    expect(screen.getByText("Blocked")).toBeVisible();
    const image = screen.getByAltText("Screenshot 1");
    expect(image.getAttribute("src")).toBe(`/admin/support/${ID}/screenshots/0`);
    expect(image.closest("a")?.getAttribute("href")).toBe(`/admin/support/${ID}/screenshots/0`);
    expect(screen.getByText("Status control: open")).toBeVisible();
  });

  it("says so when there is no screenshot", () => {
    render(<SupportDetailView item={row} />);
    expect(screen.getByText("No screenshots.")).toBeVisible();
  });
});
