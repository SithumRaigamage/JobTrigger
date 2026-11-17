import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { ChangelogView } from "./changelog-view";

describe("ChangelogView after the first release", () => {
  it("shows the released v1.0 after what comes next", () => {
    render(<ChangelogView />);

    expect(screen.getByText("Every release, newest first.")).toBeInTheDocument();

    const [next, released] = screen.getAllByRole("article");
    expect(within(next).getByRole("heading")).toHaveTextContent("Coming next");
    // The date sits beside the card, not inside it.
    expect(screen.getByText("No dates yet")).toBeInTheDocument();
    expect(screen.getByText("17 November 2026")).toBeInTheDocument();
    // "Upcoming" belongs to the pre-launch view only.
    expect(screen.queryByText("Upcoming")).not.toBeInTheDocument();

    expect(within(released).getByRole("heading")).toHaveTextContent("JobTrigger 1.0");
    expect(
      screen.getByText(/Jenkins, GitHub Actions and SonarQube in one app/),
    ).toBeInTheDocument();
  });

  it("reads each item with its tag", () => {
    render(<ChangelogView />);

    expect(screen.getByText("Password reset by email").closest("li")).toHaveTextContent(
      "Next Password reset by email",
    );
  });
});
