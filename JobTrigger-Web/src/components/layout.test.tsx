import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { Section } from "./layout";

describe("Section", () => {
  it("is a light surface by default", () => {
    render(<Section aria-label="features" />);

    const section = screen.getByRole("region", { name: "features" });
    expect(section).toHaveAttribute("data-surface", "light");
    expect(section).not.toHaveClass("bg-dot-grid");
  });

  it("switches to the dark surface with an optional dot grid", () => {
    render(<Section aria-label="hero" surface="dark" dotGrid />);

    const section = screen.getByRole("region", { name: "hero" });
    expect(section).toHaveAttribute("data-surface", "dark");
    expect(section).toHaveClass("bg-dot-grid");
  });
});
