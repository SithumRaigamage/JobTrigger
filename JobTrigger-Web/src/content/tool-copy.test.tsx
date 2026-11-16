import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { generateMetadata as integrationsMetadata } from "@/app/(marketing)/integrations/page";
import { Hero } from "@/features/marketing/home/hero";
import { ToolStrip } from "@/features/marketing/home/tool-strip";

import { useManifest } from "./release";
import {
  comingNextLine,
  integrationsDescription,
  joinNames,
  pocketLine,
  releasedToolList,
  releasedToolListShort,
} from "./tool-copy";
import manifestFile from "./tools.json";

// Marketing copy follows the release manifest. The suite runs with every tool
// released (tests/setup.ts), which must read exactly as the site always has.
const at = (release: string) => ({ release, tools: manifestFile.tools });

describe("with every tool released (the wording is what it was)", () => {
  it("lists the three tools in the usual order and has nothing coming next", () => {
    expect(releasedToolList()).toBe("Jenkins, GitHub Actions and SonarQube");
    expect(releasedToolListShort()).toBe("Jenkins, GitHub and SonarQube");
    expect(comingNextLine()).toBeNull();
    expect(pocketLine()).toEqual({
      lead: "Jenkins, GitHub Actions and SonarQube in your pocket.",
      next: null,
    });
    expect(integrationsDescription()).toBe(
      "Jenkins, GitHub Actions and SonarQube in JobTrigger: what works today, and what's coming.",
    );
  });

  it("the hero sentence is the one it always was", () => {
    render(<Hero />);
    expect(
      screen.getByText(
        "JobTrigger puts Jenkins, GitHub Actions and SonarQube in your pocket. Trigger jobs, watch logs stream live, and know the moment a build breaks.",
      ),
    ).toBeVisible();
  });

  it("the tool strip lists the three tools and no 'Coming next'", () => {
    render(<ToolStrip />);
    const strip = screen.getByLabelText("Supported tools");
    expect(strip).toHaveTextContent("Jenkins");
    expect(strip).toHaveTextContent("GitHub Actions");
    expect(strip).toHaveTextContent("SonarQube");
    expect(strip).not.toHaveTextContent("Coming next");
  });

  it("the integrations meta description is unchanged", async () => {
    const metadata = await integrationsMetadata();
    expect(metadata.description).toBe(
      "Jenkins, GitHub Actions and SonarQube in JobTrigger: what works today, and what's coming.",
    );
  });
});

describe("release 1.0 (Jenkins only)", () => {
  it("leads with Jenkins and names the rest as coming next, soonest first", () => {
    useManifest(at("1.0"));

    expect(releasedToolList()).toBe("Jenkins");
    expect(releasedToolListShort()).toBe("Jenkins");
    expect(comingNextLine()).toBe("SonarQube and GitHub Actions coming next");
    expect(pocketLine()).toEqual({
      lead: "Jenkins in your pocket.",
      next: "SonarQube and GitHub Actions coming next.",
    });
  });

  it("never names a planned tool with no code", () => {
    useManifest(at("1.0"));
    expect(comingNextLine()).not.toMatch(/GitLab|CircleCI/);
  });

  it("the hero says Jenkins is in your pocket, then what is coming", () => {
    useManifest(at("1.0"));
    render(<Hero />);

    expect(
      screen.getByText(
        "JobTrigger puts Jenkins in your pocket. SonarQube and GitHub Actions coming next. Trigger jobs, watch logs stream live, and know the moment a build breaks.",
      ),
    ).toBeVisible();
    expect(screen.queryByText(/Jenkins, GitHub Actions and SonarQube/)).not.toBeInTheDocument();
  });

  it("the tool strip lists Jenkins, then 'Coming next' with versions", () => {
    useManifest(at("1.0"));
    render(<ToolStrip />);

    const strip = screen.getByLabelText("Supported tools");
    const text = strip.textContent ?? "";
    expect(text.indexOf("Jenkins")).toBeGreaterThan(-1);
    expect(text.indexOf("Jenkins")).toBeLessThan(text.indexOf("Coming next"));
    expect(text.indexOf("Coming next")).toBeLessThan(text.indexOf("SonarQube"));
    expect(text.indexOf("SonarQube")).toBeLessThan(text.indexOf("GitHub Actions"));
    expect(within(strip).getByText("1.1")).toBeVisible();
    expect(within(strip).getByText("1.2")).toBeVisible();
    // Nothing about GitHub or SonarQube sits before "Coming next".
    expect(text.slice(0, text.indexOf("Coming next"))).not.toMatch(/GitHub|SonarQube/);
    expect(strip).not.toHaveTextContent(/GitLab|CircleCI/);
  });

  it("the integrations meta description says what works today, then what is next", async () => {
    useManifest(at("1.0"));
    expect(integrationsDescription()).toBe(
      "Jenkins in JobTrigger: what works today. SonarQube and GitHub Actions coming next.",
    );
    expect((await integrationsMetadata()).description).toBe(integrationsDescription());
  });
});

describe("release 1.1", () => {
  it("leads with Jenkins and SonarQube; GitHub Actions is next", () => {
    useManifest(at("1.1"));
    expect(releasedToolList()).toBe("Jenkins and SonarQube");
    expect(pocketLine()).toEqual({
      lead: "Jenkins and SonarQube in your pocket.",
      next: "GitHub Actions coming next.",
    });
  });
});

describe("joinNames", () => {
  it("joins like a sentence", () => {
    expect(joinNames([])).toBe("");
    expect(joinNames(["A"])).toBe("A");
    expect(joinNames(["A", "B"])).toBe("A and B");
    expect(joinNames(["A", "B", "C"])).toBe("A, B and C");
  });
});
