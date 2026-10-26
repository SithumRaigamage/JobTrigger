import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { ChangelogView } from "./changelog-view";

describe("ChangelogView before the first release", () => {
  it("shows the upcoming v1.0 then what follows, with no invented dates", () => {
    render(<ChangelogView />);

    const [first, after] = screen.getAllByRole("article");
    expect(within(first).getByRole("heading")).toHaveTextContent("First public release");
    expect(within(first).getByText("Upcoming")).toBeInTheDocument();
    expect(within(after).getByRole("heading")).toHaveTextContent("After launch");
    expect(screen.getByText("Coming soon")).toBeInTheDocument();
    expect(screen.getByText("No dates yet")).toBeInTheDocument();
  });

  it("reads each item with its tag", () => {
    render(<ChangelogView />);

    expect(screen.getByText("Password reset by email").closest("li")).toHaveTextContent(
      "Next Password reset by email",
    );
  });
});
