import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import type { FeatureId, FeatureStatus } from "@/content/feature-status";

import { Hero } from "./hero";
import { SetupBand } from "./setup-band";
import { Timeline } from "./timeline";
import { ToolStrip } from "./tool-strip";
import { Trust } from "./trust";

const overrides: Partial<Record<FeatureId, FeatureStatus>> = {};

vi.mock("@/content/feature-status", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/content/feature-status")>();
  return { ...actual, statusOf: (id: FeatureId) => overrides[id] ?? actual.statusOf(id) };
});

afterEach(() => {
  for (const key of Object.keys(overrides)) delete overrides[key as FeatureId];
});

describe("Hero", () => {
  it("leads with web setup and flags the apps as coming soon before launch", () => {
    render(<Hero />);

    // The <br> after "builds" adds no text node, hence \s*.
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
      /Ship builds\s*from anywhere\./,
    );
    expect(screen.getByRole("link", { name: "Set up your servers" })).toHaveAttribute(
      "href",
      "/sign-in",
    );
    expect(
      screen.getByRole("link", { name: /Coming soon iPhone and Android apps/ }),
    ).toHaveAttribute("href", "/#download");
  });

  it("leads with the download once the app is live", () => {
    overrides["app-stores"] = "live";
    render(<Hero />);

    expect(screen.getByRole("link", { name: "Get the app — free" })).toHaveAttribute(
      "href",
      "/#download",
    );
    expect(screen.queryByText(/see what's launching/)).not.toBeInTheDocument();
  });

  it("describes the illustration as one image", () => {
    render(<Hero />);

    expect(screen.getByRole("img", { name: /JobTrigger on a phone/ })).toBeInTheDocument();
  });
});

describe("ToolStrip", () => {
  it("badges tools that aren't fully live and lists planned ones", () => {
    render(<ToolStrip />);

    expect(screen.getByText("Beta")).toBeInTheDocument();
    expect(screen.getByText("Coming soon")).toBeInTheDocument();
    expect(screen.getByText("More planned")).toBeInTheDocument();
  });

  it("drops badges and 'More planned' as features ship", () => {
    Object.assign(overrides, {
      "github-runs": "live",
      "sonarqube-insights": "live",
      "gitlab-ci": "live",
      circleci: "live",
    });
    render(<ToolStrip />);

    expect(screen.queryByText("Beta")).not.toBeInTheDocument();
    expect(screen.queryByText("Coming soon")).not.toBeInTheDocument();
    expect(screen.queryByText("More planned")).not.toBeInTheDocument();
  });
});

describe("Timeline", () => {
  it("is an ordered list of four steps, each with a heading and one described illustration", () => {
    render(<Timeline />);

    const steps = screen.getAllByRole("listitem");
    expect(steps).toHaveLength(4);
    expect(screen.getAllByRole("heading", { level: 3 }).map((h) => h.textContent)).toEqual([
      "Start any job, with the right inputs.",
      "Logs that stream as fast as the build.",
      "See why it went red in seconds.",
      "Stop refreshing. We’ll tell you.",
    ]);
    expect(screen.getAllByRole("img")).toHaveLength(4);
  });
});

describe("SetupBand", () => {
  it("sends people to set up a server and describes its illustration", () => {
    render(<SetupBand />);

    expect(screen.getByRole("heading", { level: 2 })).toHaveTextContent(
      "Paste tokens on your laptop. Your phone already has them.",
    );
    expect(screen.getByRole("link", { name: "Set up a server →" })).toHaveAttribute(
      "href",
      "/sign-in",
    );
    expect(screen.getByRole("img", { name: /browser form with Jenkins details/ })).toBeVisible();
  });
});

describe("Trust", () => {
  it("lists four security facts and links to the security page", () => {
    render(<Trust />);

    expect(screen.getAllByRole("heading", { level: 3 }).map((h) => h.textContent)).toEqual([
      "Encrypted at rest",
      "Secure storage",
      "Masked on the web",
      "Direct to your CI",
    ]);
    expect(screen.getByRole("link", { name: "How we handle your tokens →" })).toHaveAttribute(
      "href",
      "/security",
    );
  });
});
