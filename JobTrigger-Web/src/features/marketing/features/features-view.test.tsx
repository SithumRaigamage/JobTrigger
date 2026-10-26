import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import type { FeatureStatus } from "@/content/feature-status";

import { FeaturesView } from "./features-view";

let githubRuns: FeatureStatus = "beta";

vi.mock("@/content/feature-status", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/content/feature-status")>();
  return {
    ...actual,
    statusOf: (id: Parameters<typeof actual.statusOf>[0]) =>
      id === "github-runs" ? githubRuns : actual.statusOf(id),
  };
});

afterEach(() => {
  githubRuns = "beta";
});

describe("FeaturesView", () => {
  it("lists nine feature cards under one page heading", () => {
    render(<FeaturesView />);

    expect(screen.getAllByRole("heading", { level: 1 })).toHaveLength(1);
    expect(screen.getAllByRole("heading", { level: 3 })).toHaveLength(9);
  });

  it("marks GitHub runs as beta and what's still coming while in beta", () => {
    render(<FeaturesView />);

    expect(screen.getByText("Beta")).toBeInTheDocument();
    expect(screen.getByText("Coming soon · runs · logs · history")).toBeInTheDocument();
    expect(screen.getByText(/Anything still on the way is marked/)).toBeInTheDocument();
  });

  it("drops the beta marks once GitHub runs are live", () => {
    githubRuns = "live";
    render(<FeaturesView />);

    expect(screen.queryByText("Beta")).not.toBeInTheDocument();
    expect(screen.queryByText(/on the way/)).not.toBeInTheDocument();
    expect(screen.getByText(/no roadmap promises/)).toBeInTheDocument();
  });
});
