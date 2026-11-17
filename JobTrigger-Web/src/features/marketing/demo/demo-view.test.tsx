import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { DemoView } from "./demo-view";

describe("DemoView (E2, PE-16)", () => {
  it("shows the sample servers with masked tokens", () => {
    render(<DemoView />);

    const table = screen.getByRole("region", { name: "Servers" });
    expect(within(table).getAllByText("Demo Jenkins").length).toBeGreaterThan(0);
    expect(within(table).getAllByText("Demo GitHub").length).toBeGreaterThan(0);
    expect(within(table).getAllByText("Demo SonarQube").length).toBeGreaterThan(0);
    expect(within(table).getByText("••••0001")).toBeVisible();
    // A full secret never appears.
    expect(document.body.textContent).not.toMatch(/demo-token-/);
  });

  it("has no form, no portal link and only disabled controls", () => {
    render(<DemoView />);

    expect(document.querySelector("form")).toBeNull();
    const portalLinks = screen
      .getAllByRole("link")
      .filter((link) => /^\/(servers|account)/.test(link.getAttribute("href") ?? ""));
    expect(portalLinks).toEqual([]);
    for (const name of [/^Add server/, /^Make active/, /^Edit/]) {
      for (const button of screen.getAllByRole("button", { name })) {
        expect(button).toHaveAttribute("aria-disabled", "true");
      }
    }
  });

  it("points to the real sign-in", () => {
    render(<DemoView />);

    expect(screen.getByRole("link", { name: /Set up your own servers/ })).toHaveAttribute(
      "href",
      "/sign-in",
    );
  });
});
