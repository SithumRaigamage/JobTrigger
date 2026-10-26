import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { Button } from "./button";
import { FeatureAction } from "./feature-action";
import { StatusBadge } from "./status-badge";

describe("StatusBadge", () => {
  it("shows nothing for a live feature", () => {
    const { container } = render(<StatusBadge feature="jenkins-core" />);

    expect(container).toBeEmptyDOMElement();
  });

  it.each([
    ["github-runs", "Beta", "bg-running-bg"],
    ["web-test-connection", "Coming soon", "bg-neutral-bg"],
    ["gitlab-ci", "Planned", "border-dashed"],
  ] as const)("%s reads %s", (feature, label, tone) => {
    render(<StatusBadge feature={feature} />);

    expect(screen.getByText(label)).toHaveClass(tone);
  });
});

describe("FeatureAction", () => {
  it("renders the real action for a usable feature", () => {
    render(
      <FeatureAction feature="github-runs" label="View runs">
        <Button href="/servers">View runs</Button>
      </FeatureAction>,
    );

    expect(screen.getByRole("link", { name: "View runs" })).toHaveAttribute("href", "/servers");
  });

  it("renders a badged, explained, inert control for an unavailable feature", () => {
    render(
      <FeatureAction
        feature="web-test-connection"
        label="Test connection"
        reason="You can test the connection from the app after saving."
      >
        <Button href="/test">Test connection</Button>
      </FeatureAction>,
    );

    expect(screen.queryByRole("link")).not.toBeInTheDocument();
    const control = screen.getByRole("button", { name: "Test connection Coming soon" });
    expect(control).toHaveAttribute("aria-disabled", "true");
    expect(control).toHaveAttribute("type", "button");
    expect(control).toHaveAccessibleDescription(
      "You can test the connection from the app after saving.",
    );
  });
});
