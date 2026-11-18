import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { useManifest } from "@/content/release";
import manifestFile from "@/content/tools.json";

import { FeaturesView } from "./features-view";

// The GitHub Actions section follows the release manifest, like /integrations.
// The suite runs with every tool released (tests/setup.ts). Shipped 1.0 has all
// three built tools; a staged manifest keeps the "Coming in X" path covered.
const at = (release: string) => ({ release, tools: manifestFile.tools });
const staged = {
  release: "1.0",
  tools: {
    jenkins: "1.0",
    sonarqube: "1.1",
    githubActions: "1.2",
    gitlab: "1.3",
    circleci: "1.3",
  },
};
const stagedAt = (release: string) => ({ ...staged, release });

const githubSection = () =>
  screen.getByRole("heading", { name: "Jenkins and GitHub, side by side." }).closest("section")!;

describe("FeaturesView and the release manifest", () => {
  it("an earlier release: the GitHub Actions section says when it arrives, not what it does today", () => {
    useManifest(staged);
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

  it("in the staged plan, 1.1 still has GitHub Actions ahead and 1.2 has it", () => {
    useManifest(stagedAt("1.1"));
    const { unmount } = render(<FeaturesView />);
    expect(within(githubSection()).getByText("Coming in 1.2")).toBeVisible();
    unmount();

    useManifest(stagedAt("1.2"));
    render(<FeaturesView />);
    expect(within(githubSection()).queryByText(/Coming in/)).not.toBeInTheDocument();
    expect(within(githubSection()).getByText(/Add your GitHub accounts/)).toBeVisible();
  });

  it("shipped 1.0: GitHub Actions works today, with no 'Coming in' label", () => {
    useManifest(at("1.0"));
    render(<FeaturesView />);

    const section = githubSection();
    expect(within(section).queryByText(/Coming in/)).not.toBeInTheDocument();
    expect(within(section).queryByText("Beta")).not.toBeInTheDocument();
    expect(
      within(section).getByText(
        /Add your GitHub accounts and browse repositories and workflows next to your Jenkins servers/,
      ),
    ).toBeVisible();
    expect(
      within(section).queryByText(/Runs, logs and history are on the way/),
    ).not.toBeInTheDocument();
    expect(screen.getByText(/no roadmap promises/)).toBeVisible();
  });

  it("with every tool released the page is what it was", () => {
    render(<FeaturesView />);

    const section = githubSection();
    expect(within(section).queryByText(/Coming in/)).not.toBeInTheDocument();
    expect(within(section).queryByText("Beta")).not.toBeInTheDocument();
    expect(
      within(section).getByText(
        /Add your GitHub accounts and browse repositories and workflows next to your Jenkins servers/,
      ),
    ).toBeVisible();
    expect(
      within(section).queryByText(/Runs, logs and history are on the way/),
    ).not.toBeInTheDocument();
    expect(screen.getByText(/no roadmap promises/)).toBeVisible();
  });
});
