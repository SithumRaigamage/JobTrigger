import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { Button } from "./button";

describe("Button", () => {
  it("renders a link when given an href", () => {
    render(<Button href="/sign-up">Set up your servers</Button>);

    const link = screen.getByRole("link", { name: "Set up your servers" });
    expect(link).toHaveAttribute("href", "/sign-up");
  });

  it("renders a non-submitting button by default", () => {
    render(<Button>Retry</Button>);

    expect(screen.getByRole("button", { name: "Retry" })).toHaveAttribute("type", "button");
  });

  it("keeps an explicit submit type", () => {
    render(<Button type="submit">Sign in</Button>);

    expect(screen.getByRole("button", { name: "Sign in" })).toHaveAttribute("type", "submit");
  });

  it("stays focusable but inert when disabled", () => {
    const onClick = vi.fn();
    render(
      <Button type="submit" disabled onClick={onClick}>
        Test connection
      </Button>,
    );

    const button = screen.getByRole("button", { name: "Test connection" });
    expect(button).toHaveAttribute("aria-disabled", "true");
    expect(button).not.toHaveAttribute("disabled");
    expect(button).toHaveAttribute("type", "button");
    fireEvent.click(button);
    expect(onClick).not.toHaveBeenCalled();
  });
});
