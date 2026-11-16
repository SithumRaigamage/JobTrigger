import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { PlanSection } from "@/features/account/plan-section";
import { PricingView } from "@/features/marketing/pricing/pricing-view";
import type { Subscription } from "@/domain/subscription";

import { comparison, plans, pricingFor, pricingPromises } from "./pricing";
import { getRelease, releaseView, useManifest } from "./release";
import manifestFile from "./tools.json";

// Subscription copy for a Jenkins-only release (1.0): it must not name tools
// the release doesn't ship or promise tools "together".
const at = (release: string) => ({ release, tools: manifestFile.tools });

describe("pricingFor", () => {
  it("with several tools released it is the content file, unchanged", () => {
    const result = pricingFor(getRelease());
    expect(result.plans).toBe(plans);
    expect(result.comparison).toBe(comparison);
    expect(result.promises).toBe(pricingPromises);
  });

  it("release 1.0 names no other tool and promises none together", () => {
    const result = pricingFor(releaseView(at("1.0")));
    const text = JSON.stringify(result);

    expect(text).not.toMatch(/GitHub|SonarQube/);
    expect(result.plans[1]!.highlights).toContain("More tools together as they release");
    expect(result.comparison.find((r) => r.label === "CI tools at the same time")).toEqual({
      label: "CI tools at the same time",
      free: { included: true, note: "One" },
      pro: { included: true, note: "Jenkins today; more as they release" },
    });
  });

  it("everything else in the plans is untouched at 1.0", () => {
    const result = pricingFor(releaseView(at("1.0")));
    expect(result.plans[0]).toBe(plans[0]);
    expect(result.plans[1]!.price).toBe(plans[1].price);
    expect(result.comparison.filter((r) => r.label !== "CI tools at the same time")).toEqual(
      comparison.filter((r) => r.label !== "CI tools at the same time"),
    );
  });

  it("release 1.1 already has two tools, so it uses the full wording", () => {
    expect(pricingFor(releaseView(at("1.1"))).plans).toBe(plans);
  });
});

describe("/pricing at release 1.0", () => {
  it("renders without GitHub Actions or SonarQube anywhere", () => {
    useManifest(at("1.0"));
    const { container } = render(<PricingView />);

    expect(container).not.toHaveTextContent(/GitHub|SonarQube/);
    expect(screen.getByText("More tools together as they release")).toBeVisible();
    expect(screen.getByText("Jenkins today; more as they release")).toBeVisible();
  });

  it("with every tool released it says what it always said", () => {
    const { container } = render(<PricingView />);
    expect(container).toHaveTextContent("Jenkins, GitHub Actions and SonarQube together");
    expect(container).toHaveTextContent("All of them");
  });
});

describe("the account plan card", () => {
  const pro: Subscription = {
    plan: "pro",
    billingEnabled: true,
    state: "active",
    source: "appStore",
    periodEnd: null,
    willRenew: true,
    manageOnWeb: false,
    limits: { maxCredentialsTotal: null, maxCredentialsPerTool: 25, maxPinnedJobs: null },
    features: { multiTool: true, backgroundWatch: true, homeWidget: true, insights: true },
  };

  it("doesn't say 'all tools together' while only Jenkins is released", () => {
    useManifest(at("1.0"));
    render(<PlanSection subscription={pro} />);
    expect(screen.queryByText("All tools together")).not.toBeInTheDocument();
    expect(screen.getByText("More tools as they release")).toBeVisible();
  });

  it("says it with several tools released", () => {
    render(<PlanSection subscription={pro} />);
    expect(screen.getByText("All tools together")).toBeVisible();
  });
});
