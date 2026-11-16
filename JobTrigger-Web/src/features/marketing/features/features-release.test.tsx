import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { useManifest } from "@/content/release";
import manifestFile from "@/content/tools.json";

import { FeaturesView } from "./features-view";

// The GitHub Actions section follows the release manifest, like /integrations.
// The suite runs with every tool released (tests/setup.ts).
const at = (release: string) => ({ release, tools: manifestFile.tools });

const githubSection = () =>
  screen.getByRole("heading", { name: "Jenkins and GitHub, side by side." }).closest("section")!;

describe("FeaturesView and the release manifest", () => {
  it("release 1.0: the GitHub Actions section says when it arrives, not what it does today", () => {
    useManifest(at("1.0"));
    render(<FeaturesView />);

    const section = githubSection();
    expect(within(section).getByText("Coming in 1.2")).toBeVisible();
    expect(
      within(section).getByText(/GitHub Actions arrives in release 1\.2: your GitHub accounts/),
    ).toBeVisible();
    // No claim that anything GitHub works today.
    expect(within(section).queryByText(/✓ Accounts/)).not.toBeInTheDocument();
    expect(
      within(section).queryByText(/Runs, logs and history are on the way/),
    ).not.toBeInTheDocument();
    expect(
      screen.getByText(
        /The Jenkins features below work today\. Sections for tools in a later release/,
      ),
    ).toBeVisible();
    expect(screen.queryByText(/Everything below is built today/)).not.toBeInTheDocument();
  });

  it("release 1.1 still has GitHub Actions ahead, release 1.2 has it", () => {
    useManifest(at("1.1"));
    const { unmount } = render(<FeaturesView />);
    expect(within(githubSection()).getByText("Coming in 1.2")).toBeVisible();
    unmount();

    useManifest(at("1.2"));
    render(<FeaturesView />);
    expect(within(githubSection()).queryByText(/Coming in/)).not.toBeInTheDocument();
    expect(within(githubSection()).getByText(/Add your GitHub accounts/)).toBeVisible();
  });

  it("with every tool released the page is what it was", () => {
    render(<FeaturesView />);

    const section = githubSection();
    expect(within(section).queryByText(/Coming in/)).not.toBeInTheDocument();
    expect(within(section).getByText("Beta")).toBeVisible();
    expect(
      within(section).getByText(/Add your GitHub accounts and browse repositories/),
    ).toBeVisible();
    expect(within(section).getByText("✓ Accounts · repos · workflows")).toBeVisible();
    expect(screen.getByText(/Everything below is built today/)).toBeVisible();
  });
});
