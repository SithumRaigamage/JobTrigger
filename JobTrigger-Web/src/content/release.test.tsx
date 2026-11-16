import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { StatusBadge } from "@/components/status-badge";
import { failureMessage } from "@/domain/app-failure";
import { IntegrationsView } from "@/features/marketing/integrations/integrations-view";
import { AddServerView } from "@/features/servers/add-server-view";
import { ServersView } from "@/features/servers/servers-view";
import { failureFor } from "@/server/backend-client";

import { afterLaunch, upcomingRelease } from "./changelog";
import { comingInVersion, isActionable } from "./feature-status";
import {
  MANIFEST_TO_TOOL,
  PLANNED_ONLY,
  allToolsManifest,
  compareVersions,
  getRelease,
  isToolReleased,
  releaseView,
  releasedTools,
  resetRelease,
  toolVersion,
  useManifest,
} from "./release";
import manifestFile from "./tools.json";

// The shipped manifest is release 1.0 (Jenkins only). The suite runs with
// every tool released (tests/setup.ts); these tests choose their own.
const at = (release: string) => ({ release, tools: manifestFile.tools });

describe("release manifest view", () => {
  it("the shipped manifest releases Jenkins only, the rest coming next in order", () => {
    resetRelease();
    expect(manifestFile.release).toBe("1.0");
    expect(releasedTools()).toEqual(["jenkins"]);
    expect(getRelease().comingNext.map((c) => [c.name, c.version])).toEqual([
      ["SonarQube", "1.1"],
      ["GitHub Actions", "1.2"],
      ["GitLab CI", "1.3"],
      ["CircleCI", "1.3"],
    ]);
    expect(toolVersion("github")).toBe("1.2");
  });

  it("later releases release more tools", () => {
    expect(releaseView(at("1.1")).released).toEqual(["jenkins", "sonarqube"]);
    expect(releaseView(at("1.2")).released).toEqual(["jenkins", "sonarqube", "github"]);
    expect(releaseView(at("1.2")).comingNext.map((c) => c.id)).toEqual(["gitlab", "circleci"]);
  });

  it("compares versions as numbers: 1.10 is after 1.2", () => {
    expect(compareVersions("1.10", "1.2")).toBeGreaterThan(0);
    expect(
      releaseView({ release: "1.2", tools: { jenkins: "1.0", sonarqube: "1.10" } }).released,
    ).toEqual(["jenkins"]);
  });

  it("the all-tools test manifest releases every tool with code and nothing planned", () => {
    const view = releaseView(allToolsManifest());
    expect(view.released.sort()).toEqual(["github", "jenkins", "sonarqube"]);
    expect(view.comingNext.map((c) => c.id)).toEqual(["gitlab", "circleci"]);
  });
});

describe("manifest ids map to the portal's tools", () => {
  it("every tool in the shipped manifest maps to a known tool or is planned only", () => {
    for (const id of Object.keys(manifestFile.tools)) {
      expect(id in MANIFEST_TO_TOOL || id in PLANNED_ONLY, id).toBe(true);
    }
  });

  it('"githubActions" is the portal\'s "github"; nothing else is renamed', () => {
    expect(MANIFEST_TO_TOOL).toEqual({
      jenkins: "jenkins",
      githubActions: "github",
      sonarqube: "sonarqube",
    });
  });

  it("an unknown id fails loudly", () => {
    expect(() => releaseView({ release: "1.0", tools: { jenkins: "1.0", gitea: "1.1" } })).toThrow(
      'Unknown tool "gitea"',
    );
  });

  it("a released tool with no code, a bad version or a bad manifest fails loudly", () => {
    expect(() => releaseView({ release: "1.3", tools: { jenkins: "1.0", gitlab: "1.3" } })).toThrow(
      "released but has no code",
    );
    expect(() => releaseView({ release: "1.0", tools: { jenkins: "one" } })).toThrow("bad version");
    expect(() => releaseView({ release: "x", tools: {} })).toThrow("not a release manifest");
  });
});

describe("the site follows the release (1.0, Jenkins only)", () => {
  it("feature statuses read as 'Coming in X' for tools not in the release", () => {
    useManifest(at("1.0"));
    expect(comingInVersion("github-accounts")).toBe("1.2");
    expect(comingInVersion("sonarqube-save")).toBe("1.1");
    expect(comingInVersion("jenkins-core")).toBeNull();
    // A feature that is "live" in the build is still not actionable if its tool isn't shipped.
    expect(isActionable("github-accounts")).toBe(false);
    expect(isActionable("jenkins-core")).toBe(true);

    render(<StatusBadge feature="sonarqube-save" />);
    expect(screen.getByText("Coming in 1.1")).toBeVisible();
  });

  it("with every tool released nothing changes", () => {
    expect(comingInVersion("github-accounts")).toBeNull();
    expect(isActionable("github-accounts")).toBe(true);
  });

  it("the integrations page labels GitHub Actions and SonarQube with their release", () => {
    useManifest(at("1.0"));
    render(<IntegrationsView supportEmail={null} />);

    expect(screen.getAllByText("Coming in 1.2").length).toBeGreaterThan(1);
    expect(screen.getAllByText("Coming in 1.1").length).toBeGreaterThan(1);
    expect(screen.getByText("Full support")).toBeVisible();
  });

  it("the portal's tool picker offers Jenkins only, with the rest under Coming next", () => {
    useManifest(at("1.0"));
    render(<AddServerView tool="jenkins" />);

    const picker = screen.getByRole("navigation", { name: "Tool" });
    expect(within(picker).getAllByRole("link")).toHaveLength(1);
    expect(within(picker).getByRole("link", { name: /Jenkins/ })).toBeVisible();
    const next = screen.getByRole("region", { name: "Coming next" });
    for (const [name, version] of [
      ["SonarQube", "1.1"],
      ["GitHub Actions", "1.2"],
      ["GitLab CI", "1.3"],
      ["CircleCI", "1.3"],
    ]) {
      const item = within(next).getByText(name!).closest("li")!;
      // Not a link, not a button: nothing to choose.
      expect(within(item).queryByRole("link")).not.toBeInTheDocument();
      expect(within(item).getByText(version!)).toBeVisible();
    }
  });

  it("with every tool released the picker offers all three and no Coming next", () => {
    render(<AddServerView tool="jenkins" />);

    expect(
      within(screen.getByRole("navigation", { name: "Tool" })).getAllByRole("link"),
    ).toHaveLength(3);
    // Only GitLab CI and CircleCI are left (no code yet).
    expect(screen.getByRole("region", { name: "Coming next" })).toBeVisible();
  });

  it("the saved-servers counts hide an unreleased tool unless something is saved for it", () => {
    useManifest(at("1.0"));
    const { rerender } = render(<ServersView servers={[]} failure={null} />);
    expect(isToolReleased("github")).toBe(false);
    expect(screen.queryByText(/GitHub/)).not.toBeInTheDocument();

    rerender(
      <ServersView
        servers={[
          {
            tool: "github",
            id: "g1",
            label: "Work",
            defaultOwner: "",
            isDefault: true,
            needsReentry: false,
            secretMask: "••••abcd",
          },
        ]}
        failure={null}
      />,
    );
    expect(screen.getAllByText(/GitHub/).length).toBeGreaterThan(0);
  });

  it("the changelog doesn't say GitHub Actions or SonarQube ship in this release", () => {
    useManifest(at("1.0"));
    const ships = upcomingRelease().map((line) => line.text);
    expect(ships.join(" ")).not.toMatch(/GitHub|SonarQube/);
    expect(ships.join(" ")).toMatch(/Jenkins/);

    const later = afterLaunch().map((line) => line.text);
    expect(later).toContain("GitHub Actions: accounts, repositories and workflows (release 1.2)");
    expect(later.some((text) => text.includes("(release 1.1)"))).toBe(true);
  });
});

describe("the backend's 'not available yet' answer", () => {
  it("is its own failure, with plain copy", () => {
    expect(
      failureFor(
        403,
        { message: "This tool is not available yet", code: "TOOL_NOT_AVAILABLE" },
        null,
      ),
    ).toEqual({ kind: "toolUnavailable" });
    expect(failureMessage({ kind: "toolUnavailable" })).toBe(
      "This tool isn't available yet in this release of JobTrigger.",
    );
  });

  it("other 403s are unchanged", () => {
    expect(failureFor(403, { message: "Forbidden" }, null)).toEqual({
      kind: "server",
      status: 403,
    });
  });
});
