import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { RevealToken } from "./reveal-token";

describe("RevealToken", () => {
  it("shows the mask, reveals on tap, hides again", async () => {
    const action = vi.fn().mockResolvedValue({ secret: "ghp_full_secret" });
    render(<RevealToken mask="ghp_••••" action={action} />);
    expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_••••");

    fireEvent.click(screen.getByRole("button", { name: "Show saved token" }));
    await waitFor(() =>
      expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_full_secret"),
    );

    fireEvent.click(screen.getByRole("button", { name: "Hide saved token" }));
    expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_••••");
    expect(action).toHaveBeenCalledTimes(1);
  });

  it("shows an error when the token can't be read", async () => {
    const action = vi.fn().mockResolvedValue({ error: "nope" });
    render(<RevealToken mask="••••" action={action} />);
    fireEvent.click(screen.getByRole("button", { name: "Show saved token" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("nope");
  });

  it("copies the full token without showing it", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.assign(navigator, { clipboard: { writeText } });
    const action = vi.fn().mockResolvedValue({ secret: "ghp_full_secret" });
    render(<RevealToken mask="ghp_••••" action={action} />);
    fireEvent.click(screen.getByRole("button", { name: "Copy saved token" }));
    await waitFor(() => expect(writeText).toHaveBeenCalledWith("ghp_full_secret"));
    expect(screen.getByTestId("saved-token")).toHaveTextContent("ghp_••••");
  });
});
