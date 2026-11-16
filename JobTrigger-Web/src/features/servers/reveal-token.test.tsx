import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { RevealToken } from "./reveal-token";

// The default 1 s wait is too tight when the whole suite runs in parallel.
const slow = { timeout: 5000 };

// The action now takes the account password (reveal needs it): every test
// confirms the password before anything shows.
function confirm(password = "pw-1", name: string | RegExp = /Confirm and/) {
  fireEvent.change(screen.getByLabelText("Account password"), { target: { value: password } });
  fireEvent.click(screen.getByRole("button", { name }));
}

describe("RevealToken", () => {
  it("shows the mask, asks for the password on tap, reveals, hides again", async () => {
    const action = vi.fn().mockResolvedValue({ secret: "ghp_full_secret" });
    render(<RevealToken mask="ghp_••••" action={action} />);
    expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_••••");

    fireEvent.click(screen.getByRole("button", { name: "Show saved token" }));
    // Nothing is requested until the password is confirmed.
    expect(action).not.toHaveBeenCalled();
    expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_••••");

    confirm("pw-1", "Confirm and show");
    await waitFor(
      () => expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_full_secret"),
      slow,
    );
    expect(action).toHaveBeenCalledWith("pw-1");
    expect(screen.queryByLabelText("Account password")).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Hide saved token" }));
    expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_••••");
    expect(action).toHaveBeenCalledTimes(1);
  });

  it("a wrong password shows the error and reveals nothing", async () => {
    const action = vi.fn().mockResolvedValue({ error: "Current password is incorrect" });
    render(<RevealToken mask="••••a91f" action={action} />);

    fireEvent.click(screen.getByRole("button", { name: "Show saved token" }));
    confirm("wrong");

    expect(await screen.findByRole("alert", {}, slow)).toHaveTextContent(
      "Current password is incorrect",
    );
    expect(screen.getByTestId("saved-token")).toHaveTextContent("••••a91f");
    // The prompt stays for another try, with the password cleared.
    expect(screen.getByLabelText("Account password")).toHaveValue("");
  });

  it("cancel closes the prompt without asking", () => {
    const action = vi.fn();
    render(<RevealToken mask="••••" action={action} />);

    fireEvent.click(screen.getByRole("button", { name: "Show saved token" }));
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }));

    expect(screen.queryByLabelText("Account password")).not.toBeInTheDocument();
    expect(action).not.toHaveBeenCalled();
  });

  it("copies the full token after the password, without showing it", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.assign(navigator, { clipboard: { writeText } });
    const action = vi.fn().mockResolvedValue({ secret: "ghp_full_secret" });
    render(<RevealToken mask="ghp_••••" action={action} />);

    fireEvent.click(screen.getByRole("button", { name: "Copy saved token" }));
    expect(writeText).not.toHaveBeenCalled();
    confirm("pw-1", "Confirm and copy");

    await waitFor(() => expect(writeText).toHaveBeenCalledWith("ghp_full_secret"), slow);
    expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_••••");
  });
});
