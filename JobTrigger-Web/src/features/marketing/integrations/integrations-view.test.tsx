import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { IntegrationsView } from "./integrations-view";
import { toolRequestHref } from "./tool-request";

describe("toolRequestHref", () => {
  it("matches the app's pre-addressed tool request email", () => {
    expect(toolRequestHref("help@jobtrigger.app")).toBe(
      "mailto:help@jobtrigger.app?subject=JobTrigger%20tool%20request&body=The%20CI%2FCD%20tool%20I%20would%20like%20to%20use%3A%20",
    );
  });
});

describe("IntegrationsView", () => {
  it("badges each tool from the feature list", () => {
    render(<IntegrationsView supportEmail={null} />);

    const cards = screen.getAllByRole("article");
    expect(within(cards[0]).getByText("Full support")).toBeInTheDocument();
    expect(within(cards[1]).getByText("Beta")).toBeInTheDocument();
    expect(within(cards[2]).getByText("Coming soon")).toBeInTheDocument();
  });

  it("never marks unbuilt GitHub capabilities as usable", () => {
    render(<IntegrationsView supportEmail={null} />);

    const row = screen.getByRole("row", { name: /Live logs/ });
    const cells = within(row).getAllByRole("cell");
    expect(cells[0]).toHaveTextContent("✓ Yes");
    expect(cells[1]).toHaveTextContent("Soon");
    expect(cells[2]).toHaveTextContent("— n/a");
  });

  it("lists planned tools and links the request to support email", () => {
    render(<IntegrationsView supportEmail="help@jobtrigger.app" />);

    expect(screen.getByText("Planned, no date yet: GitLab CI and CircleCI.")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Request a tool →" })).toHaveAttribute(
      "href",
      toolRequestHref("help@jobtrigger.app"),
    );
  });

  it("falls back to the support page without a support address", () => {
    render(<IntegrationsView supportEmail={null} />);

    expect(screen.getByRole("link", { name: "Request a tool →" })).toHaveAttribute(
      "href",
      "/support",
    );
  });
});
