import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import type { FeatureId, FeatureStatus } from "@/content/feature-status";

import { FeaturesView } from "./features-view";

const overrides: Partial<Record<FeatureId, FeatureStatus>> = {};

vi.mock("@/content/feature-status", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/content/feature-status")>();
  return {
    ...actual,
    statusOf: (id: FeatureId) => overrides[id] ?? actual.statusOf(id),
  };
});

afterEach(() => {
  for (const key of Object.keys(overrides)) delete overrides[key as FeatureId];
});

describe("FeaturesView", () => {
  it("lists nine feature cards under one page heading", () => {
    render(<FeaturesView />);

    expect(screen.getAllByRole("heading", { level: 1 })).toHaveLength(1);
    expect(screen.getAllByRole("heading", { level: 3 })).toHaveLength(9);
  });

  it("shows no beta marks now that GitHub Actions and its runs are live", () => {
    render(<FeaturesView />);

    expect(screen.queryByText("Beta")).not.toBeInTheDocument();
    expect(screen.queryByText(/on the way/)).not.toBeInTheDocument();
    expect(screen.getByText(/no roadmap promises/)).toBeInTheDocument();
  });

  it("marks runs as still coming if that feature is not live yet", () => {
    overrides["github-runs"] = "soon";
    render(<FeaturesView />);

    expect(screen.queryByText("Beta")).not.toBeInTheDocument();
    expect(screen.getByText("Coming soon · runs · logs · history")).toBeInTheDocument();
    expect(screen.getByText(/Anything still on the way is marked/)).toBeInTheDocument();
  });
});
