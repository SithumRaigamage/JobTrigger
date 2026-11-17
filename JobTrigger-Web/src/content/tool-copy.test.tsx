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

// Marketing copy follows the release manifest. The shipped 1.0 releases all
// three built tools, and the suite runs with every tool released
// (tests/setup.ts); both must read exactly as the site always has. A staged
// manifest keeps the coming-next wording covered for an earlier release.
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

describe("with all built tools released (the shipped 1.0 wording)", () => {
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

  it("the shipped 1.0 manifest reads the same way", () => {
    useManifest(at("1.0"));
    expect(releasedToolList()).toBe("Jenkins, GitHub Actions and SonarQube");
    expect(comingNextLine()).toBeNull();
    expect(pocketLine().next).toBeNull();
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

describe("an earlier release with tools still to come", () => {
  it("leads with the released tools and names the rest as coming next, soonest first", () => {
    useManifest(staged);

    expect(releasedToolList()).toBe("Jenkins");
    expect(releasedToolListShort()).toBe("Jenkins");
    expect(comingNextLine()).toBe("SonarQube and GitHub Actions coming next");
    expect(pocketLine()).toEqual({
      lead: "Jenkins in your pocket.",
      next: "SonarQube and GitHub Actions coming next.",
    });
  });

  it("never names a planned tool with no code", () => {
    useManifest(staged);
    expect(comingNextLine()).not.toMatch(/GitLab|CircleCI/);
  });

  it("the hero says the released tool is in your pocket, then what is coming", () => {
    useManifest(staged);
    render(<Hero />);

    expect(
      screen.getByText(
        "JobTrigger puts Jenkins in your pocket. SonarQube and GitHub Actions coming next. Trigger jobs, watch logs stream live, and know the moment a build breaks.",
      ),
    ).toBeVisible();
    expect(screen.queryByText(/Jenkins, GitHub Actions and SonarQube/)).not.toBeInTheDocument();
  });

  it("the tool strip lists the released tool, then 'Coming next' with versions", () => {
    useManifest(staged);
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
    useManifest(staged);
    expect(integrationsDescription()).toBe(
      "Jenkins in JobTrigger: what works today. SonarQube and GitHub Actions coming next.",
    );
    expect((await integrationsMetadata()).description).toBe(integrationsDescription());
  });
});

describe("release 1.1 in the staged plan", () => {
  it("leads with Jenkins and SonarQube; GitHub Actions is next", () => {
    useManifest(stagedAt("1.1"));
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
