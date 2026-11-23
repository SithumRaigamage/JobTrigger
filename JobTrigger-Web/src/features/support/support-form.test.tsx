import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

const submitSupportAction = vi.fn(async (..._args: unknown[]) => ({}));

vi.mock("./actions", () => ({
  submitSupportAction: (...args: unknown[]) => submitSupportAction(...args),
}));

import { SupportForm } from "./support-form";

const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]);

beforeEach(() => submitSupportAction.mockReset().mockResolvedValue({}));

describe("SupportForm (US-SUP-05/06)", () => {
  it("offers seven kinds, the areas, the impact and the blur warning", () => {
    render(<SupportForm replyEmail="sam@acme.dev" />);
    for (const label of [
      "Bug",
      "Feature idea",
      "Question",
      "Tool request",
      "Account & sign-in",
      "Billing & subscription",
      "Something else",
      "GitHub Actions",
      "Phone/app",
      "Blocked",
      "Minor",
    ]) {
      expect(screen.getByText(label)).toBeVisible();
    }
    expect(screen.getByText(/Blur tokens, passwords and personal data/)).toBeVisible();
    expect(screen.getByText(/Signed in as sam@acme.dev/)).toBeVisible();
    expect(screen.queryByText(/^Token$/)).not.toBeInTheDocument();
  });

  it("previews a picked image and lets it be removed before sending", async () => {
    render(<SupportForm replyEmail="sam@acme.dev" />);
    const input = screen.getByLabelText(/Screenshots/);
    const file = new File([PNG], "shot.png", { type: "image/png" });
    fireEvent.change(input, { target: { files: [file] } });

    expect(await screen.findByText("Remove shot.png")).toBeVisible();
    fireEvent.click(screen.getByText("Remove shot.png"));
    expect(screen.queryByText("Remove shot.png")).not.toBeInTheDocument();
  });

  it("submits the held files with the text and options", async () => {
    render(<SupportForm replyEmail="sam@acme.dev" />);
    fireEvent.change(screen.getByLabelText("Subject"), { target: { value: "Blank log" } });
    fireEvent.change(screen.getByLabelText("Details"), { target: { value: "No output." } });
    fireEvent.click(screen.getByLabelText("GitHub Actions"));
    fireEvent.change(screen.getByLabelText("Impact"), { target: { value: "blocked" } });
    const file = new File([PNG], "shot.png", { type: "image/png" });
    fireEvent.change(screen.getByLabelText(/Screenshots/), { target: { files: [file] } });
    await screen.findByText("Remove shot.png");

    fireEvent.click(screen.getByRole("button", { name: "Send report" }));
    await waitFor(() => expect(submitSupportAction).toHaveBeenCalledTimes(1));
    const data = submitSupportAction.mock.calls[0]![1] as FormData;
    expect(data.get("subject")).toBe("Blank log");
    expect(data.get("message")).toBe("No output.");
    expect(data.get("category")).toBe("bug");
    expect(data.get("impact")).toBe("blocked");
    expect(data.getAll("areas")).toEqual(["github"]);
    expect((data.getAll("screenshots")[0] as File).name).toBe("shot.png");
  });

  it("shows the ticket id after a successful send", async () => {
    submitSupportAction.mockResolvedValue({
      sent: { ticketId: "t31", replyEmail: "sam@acme.dev" },
    });
    render(<SupportForm replyEmail="sam@acme.dev" />);
    fireEvent.click(screen.getByRole("button", { name: "Send report" }));
    expect(await screen.findByText(/Ticket t31/)).toBeVisible();
  });
});
