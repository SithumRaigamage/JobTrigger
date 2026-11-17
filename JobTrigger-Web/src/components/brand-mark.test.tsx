import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { BrandMark } from "./brand-mark";

describe("BrandMark", () => {
  it("reads as the name alone: the mark is decorative", () => {
    render(
      <a href="#home">
        <BrandMark />
      </a>,
    );

    expect(screen.getByRole("link")).toHaveAccessibleName("JobTrigger");
    expect(document.querySelector("svg")).toHaveAttribute("aria-hidden", "true");
  });

  it("draws Concept B: two stages and a run arrow on the tile", () => {
    const { container } = render(<BrandMark />);

    expect(container.querySelector("rect.fill-logo-tile")).not.toBeNull();
    expect(container.querySelectorAll("circle.stroke-logo-stage")).toHaveLength(2);
    expect(container.querySelector("path.fill-logo-run")).not.toBeNull();
  });

  it("uses no inline style, so the strict CSP allows it", () => {
    const { container } = render(<BrandMark glow />);

    expect(container.querySelector("[style]")).toBeNull();
  });
});
