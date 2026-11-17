import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { PlanSection } from "@/features/account/plan-section";
import { PricingView } from "@/features/marketing/pricing/pricing-view";
import type { Subscription } from "@/domain/subscription";

import { comparison, plans, pricingFor, pricingPromises } from "./pricing";
import { getRelease, releaseView, useManifest } from "./release";
import manifestFile from "./tools.json";

// Subscription copy follows the release manifest. Shipped 1.0 releases all
// three built tools, so the full wording applies; a staged manifest keeps the
// single-tool gating logic covered.
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

describe("pricingFor", () => {
  it("with several tools released it is the content file, unchanged", () => {
    const result = pricingFor(getRelease());
    expect(result.plans).toBe(plans);
    expect(result.comparison).toBe(comparison);
    expect(result.promises).toBe(pricingPromises);
  });

  it("the shipped 1.0 release uses the full wording", () => {
    expect(pricingFor(releaseView(at("1.0"))).plans).toBe(plans);
  });

  it("a single-tool release names no other tool and promises none together", () => {
    const result = pricingFor(releaseView(staged));
    const text = JSON.stringify(result);

    expect(text).not.toMatch(/GitHub|SonarQube/);
    expect(result.plans[1]!.highlights).toContain("More tools together as they release");
    expect(result.comparison.find((r) => r.label === "CI tools at the same time")).toEqual({
      label: "CI tools at the same time",
      free: { included: true, note: "One" },
      pro: { included: true, note: "Jenkins today; more as they release" },
    });
  });

  it("everything else in the plans is untouched in a single-tool release", () => {
    const result = pricingFor(releaseView(staged));
    expect(result.plans[0]).toBe(plans[0]);
    expect(result.plans[1]!.price).toBe(plans[1].price);
    expect(result.comparison.filter((r) => r.label !== "CI tools at the same time")).toEqual(
      comparison.filter((r) => r.label !== "CI tools at the same time"),
    );
  });

  it("release 1.1 already has two tools, so it uses the full wording", () => {
    expect(pricingFor(releaseView({ ...staged, release: "1.1" })).plans).toBe(plans);
  });
});

describe("/pricing at release 1.0", () => {
  it("the shipped 1.0 release names all three tools", () => {
    useManifest(at("1.0"));
    const { container } = render(<PricingView />);

    expect(container).toHaveTextContent("Jenkins, GitHub Actions and SonarQube together");
    expect(container).toHaveTextContent("All of them");
  });

  it("a single-tool release renders without GitHub Actions or SonarQube anywhere", () => {
    useManifest(staged);
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

  it("doesn't say 'all tools together' in a single-tool release", () => {
    useManifest(staged);
    render(<PlanSection subscription={pro} />);
    expect(screen.queryByText("All tools together")).not.toBeInTheDocument();
    expect(screen.getByText("More tools as they release")).toBeVisible();
  });

  it("says it for the shipped 1.0 release", () => {
    useManifest(at("1.0"));
    render(<PlanSection subscription={pro} />);
    expect(screen.getByText("All tools together")).toBeVisible();
  });

  it("says it with several tools released", () => {
    render(<PlanSection subscription={pro} />);
    expect(screen.getByText("All tools together")).toBeVisible();
  });
});
