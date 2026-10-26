import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { SecurityView } from "./security-view";

describe("SecurityView", () => {
  it("describes the token flow diagram and lists six facts", () => {
    render(<SecurityView />);

    expect(screen.getByRole("img", { name: /phone talks directly to Jenkins/ })).toBeVisible();
    expect(screen.getAllByRole("listitem").length).toBeGreaterThanOrEqual(6);
    expect(screen.getByRole("heading", { name: "Short sessions" })).toBeInTheDocument();
  });

  it("shows the reporting placeholders as text, not a dead mailto", () => {
    render(<SecurityView />);

    expect(screen.getByText("[SECURITY EMAIL]").tagName).toBe("SPAN");
    expect(screen.queryByRole("link", { name: /SECURITY EMAIL/ })).not.toBeInTheDocument();
    expect(screen.getByText(/We reply within \[N\] working days/)).toBeInTheDocument();
  });

  it("links to the token guides in the portal", () => {
    render(<SecurityView />);

    expect(screen.getByRole("link", { name: "Step-by-step token guides →" })).toHaveAttribute(
      "href",
      "/servers/new",
    );
  });
});
