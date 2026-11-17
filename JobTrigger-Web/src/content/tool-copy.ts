import type { Tool } from "@/domain/credentials";

import { getRelease } from "./release";

/*
 * Marketing wording about which tools JobTrigger works with, built from the
 * release manifest (release/tools.json) so a page can never lead with a tool
 * the release doesn't ship. Tools the release does ship come first; tools
 * with code that a later release ships are named only as "coming next".
 *
 * Release 1.0 ships all three built tools, so the sentences here are the ones
 * the site always had ("Jenkins, GitHub Actions and SonarQube"). Planned tools
 * with no code (GitLab CI, CircleCI) are never named here: their "Coming next"
 * entry lives in the portal's pickers, straight from the manifest.
 */

/** The order the site has always listed tools in. */
const displayOrder: Tool[] = ["jenkins", "github", "sonarqube"];

const fullNames: Record<Tool, string> = {
  jenkins: "Jenkins",
  github: "GitHub Actions",
  sonarqube: "SonarQube",
};

const shortNames: Record<Tool, string> = {
  jenkins: "Jenkins",
  github: "GitHub",
  sonarqube: "SonarQube",
};

/** "A", "A and B", "A, B and C". */
export function joinNames(names: string[]): string {
  if (names.length <= 1) return names[0] ?? "";
  return `${names.slice(0, -1).join(", ")} and ${names.at(-1)}`;
}

/** Released tools, in the site's usual order. */
export function releasedInOrder(): Tool[] {
  const { released } = getRelease();
  return displayOrder.filter((tool) => released.includes(tool));
}

/** Tools we have built that a later release ships, soonest first. */
export function comingNextTools(): { tool: Tool; name: string; version: string }[] {
  return getRelease().comingNext.flatMap((next) =>
    next.tool ? [{ tool: next.tool, name: fullNames[next.tool], version: next.version }] : [],
  );
}

/** "Jenkins, GitHub Actions and SonarQube": the released tools. */
export function releasedToolList(): string {
  return joinNames(releasedInOrder().map((tool) => fullNames[tool]));
}

/** "Jenkins, GitHub and SonarQube": the released tools, short names. */
export function releasedToolListShort(): string {
  return joinNames(releasedInOrder().map((tool) => shortNames[tool]));
}

/** "SonarQube and GitHub Actions coming next", or null when nothing is. */
export function comingNextLine(): string | null {
  const next = comingNextTools();
  if (next.length === 0) return null;
  return `${joinNames(next.map((n) => n.name))} coming next`;
}

/** The hero and preview-image sentence: the released tools "in your pocket". */
export function pocketLine(): { lead: string; next: string | null } {
  const next = comingNextLine();
  return {
    lead: `${releasedToolList()} in your pocket.`,
    next: next === null ? null : `${next[0]!.toUpperCase()}${next.slice(1)}.`,
  };
}

/** The integrations page's meta description. */
export function integrationsDescription(): string {
  const next = comingNextLine();
  return next === null
    ? `${releasedToolList()} in JobTrigger: what works today, and what's coming.`
    : `${releasedToolList()} in JobTrigger: what works today. ${next[0]!.toUpperCase()}${next.slice(1)}.`;
}
