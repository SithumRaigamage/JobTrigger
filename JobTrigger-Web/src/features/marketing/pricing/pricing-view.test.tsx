import { render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { comparison, plans } from "@/content/pricing";
import type { FeatureId, FeatureStatus } from "@/content/feature-status";

import { mainNav, routes } from "../site-links";
import { publicPaths } from "../public-pages";

import { PricingView } from "./pricing-view";

const overrides: Partial<Record<FeatureId, FeatureStatus>> = {};

vi.mock("@/content/feature-status", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/content/feature-status")>();
  const statusOf = (id: FeatureId) => overrides[id] ?? actual.statusOf(id);
  return {
    ...actual,
    statusOf,
    isActionable: (id: FeatureId) => ["live", "beta"].includes(statusOf(id)),
  };
});

afterEach(() => {
  for (const key of Object.keys(overrides)) delete overrides[key as FeatureId];
});

describe("PricingView", () => {
  it("lists both plans and every comparison row from the content file", () => {
    render(<PricingView />);

    expect(screen.getByRole("heading", { level: 1 })).toBeVisible();
    for (const plan of plans) {
      expect(
        screen.getByRole("heading", { level: 2, name: plan.id === "pro" ? /^Pro/ : plan.name }),
      ).toBeVisible();
      expect(screen.getByText(plan.price)).toBeVisible();
    }
    const table = screen.getByRole("table", { name: "What Free and Pro include" });
    expect(within(table).getAllByRole("row")).toHaveLength(comparison.length + 1);
  });

  it("says in words what is not included, not by colour alone", () => {
    render(<PricingView />);
    const row = screen.getByRole("row", { name: /Home-screen widget/ });
    expect(row).toHaveTextContent("Not included");
    expect(row).toHaveTextContent("Included");
  });

  it("while billing is off: Pro shows Coming soon and there is no buy button or checkout link", () => {
    render(<PricingView />);

    const action = screen.getByRole("button", { name: /Get Pro in the app/ });
    expect(action).toHaveAttribute("aria-disabled", "true");
    expect(action).toHaveTextContent("Coming soon");
    expect(screen.getByText(/Pro isn't on sale yet/)).toBeVisible();
    expect(screen.queryByRole("link", { name: /Get Pro in the app/ })).not.toBeInTheDocument();
    for (const link of screen.getAllByRole("link")) {
      expect(link.getAttribute("href") ?? "").not.toMatch(/paddle|checkout|buy/i);
    }
  });

  it("once subscriptions are live: Pro links to the download section", () => {
    overrides.subscriptions = "live";
    render(<PricingView />);

    expect(screen.getByRole("link", { name: "Get Pro in the app" })).toHaveAttribute(
      "href",
      routes.download,
    );
    expect(screen.queryByText("Coming soon")).not.toBeInTheDocument();
  });

  it("is in the header, the footer's sitemap list and the public pages", () => {
    expect(mainNav.some((item) => item.href === "/pricing" && item.label === "Pricing")).toBe(true);
    expect(publicPaths).toContain("/pricing");
  });
});

describe("PricingView student offer (Phase 21)", () => {
  it("is not shown while billing is off", () => {
    render(<PricingView />);
    expect(screen.queryByTestId("student-offer")).not.toBeInTheDocument();
    expect(screen.queryByText(/Students get Pro free/)).not.toBeInTheDocument();
  });

  it("says students get Pro free for one year once Pro is on sale", () => {
    overrides.subscriptions = "live";
    render(<PricingView />);
    const offer = screen.getByTestId("student-offer");
    expect(offer).toHaveTextContent("Students get Pro free for one year.");
    expect(offer).toHaveTextContent("one free year per person");
  });
});
