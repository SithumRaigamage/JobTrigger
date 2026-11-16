import type { Tool } from "@/domain/credentials";

// Imported by its @/ name so the end-to-end build can swap in an all-tools
// manifest (next.config.ts, E2E_ALL_TOOLS). Nothing else ever does.
import manifestFile from "@/content/tools.json";

/*
 * Which tools this release supports: release/tools.json, copied to
 * content/tools.json by scripts/sync-tools.mjs. The integrations page, the
 * portal's tool pickers and the feature-status labels read it, so a tool
 * that isn't in this release never looks available.
 *
 * The manifest calls GitHub Actions "githubActions"; the portal's Tool type,
 * routes and stored data call it "github". MANIFEST_TO_TOOL is the one place
 * that knows both. Nothing is renamed.
 */

/** Manifest id -> the portal's tool. */
export const MANIFEST_TO_TOOL = {
  jenkins: "jenkins",
  githubActions: "github",
  sonarqube: "sonarqube",
} as const satisfies Record<string, Tool>;

/** Planned in the manifest, no code here yet: shown as "Coming next" only. */
export const PLANNED_ONLY = { gitlab: "GitLab CI", circleci: "CircleCI" } as const;

export type ReleaseManifest = { release: string; tools: Record<string, string> };

export type ComingNext = {
  /** The manifest id. */
  id: string;
  name: string;
  version: string;
  /** Set for a tool with code here that this release doesn't ship yet. */
  tool?: Tool;
};

export type ReleaseView = {
  release: string;
  /** Released tools, in manifest order. */
  released: Tool[];
  /** The release each tool with code ships in. */
  versions: Partial<Record<Tool, string>>;
  /** Not released yet, soonest first. */
  comingNext: ComingNext[];
};

const VERSION = /^\d+\.\d+$/;

/** `1.10` is after `1.2`: numbers, not text. */
export function compareVersions(a: string, b: string): number {
  const [aMajor, aMinor] = a.split(".").map(Number) as [number, number];
  const [bMajor, bMinor] = b.split(".").map(Number) as [number, number];
  return aMajor - bMajor || aMinor - bMinor;
}

const namesById: Record<string, string> = {
  jenkins: "Jenkins",
  githubActions: "GitHub Actions",
  sonarqube: "SonarQube",
  ...PLANNED_ONLY,
};

/**
 * [manifest] as this site uses it. Throws on an id the site doesn't know, a
 * bad version, or a released tool with no code, so a typo or a half-added
 * tool never silently opens or closes a door.
 */
export function releaseView(manifest: ReleaseManifest): ReleaseView {
  if (!VERSION.test(manifest?.release ?? "") || typeof manifest.tools !== "object") {
    throw new Error("content/tools.json is not a release manifest");
  }
  const released: Tool[] = [];
  const versions: Partial<Record<Tool, string>> = {};
  const comingNext: ComingNext[] = [];
  for (const [id, version] of Object.entries(manifest.tools)) {
    if (!VERSION.test(version)) {
      throw new Error(`Tool "${id}": bad version ${JSON.stringify(version)}`);
    }
    const tool = (MANIFEST_TO_TOOL as Record<string, Tool | undefined>)[id];
    const isReleased = compareVersions(version, manifest.release) <= 0;
    if (tool === undefined && !(id in PLANNED_ONLY)) {
      throw new Error(`Unknown tool "${id}" in content/tools.json`);
    }
    if (tool === undefined && isReleased) {
      throw new Error(`Tool "${id}" is released but has no code here`);
    }
    if (tool !== undefined) versions[tool] = version;
    if (isReleased && tool !== undefined) released.push(tool);
    else if (!isReleased) {
      comingNext.push({ id, name: namesById[id]!, version, ...(tool ? { tool } : {}) });
    }
  }
  // Soonest release first; the sort is stable, so manifest order breaks ties.
  comingNext.sort((a, b) => compareVersions(a.version, b.version));
  return { release: manifest.release, released, versions, comingNext };
}

/** Tests: the shipped manifest with every tool that has code released. */
export function allToolsManifest(): ReleaseManifest {
  return {
    release: "98.0",
    tools: Object.fromEntries(
      Object.keys(manifestFile.tools).map((id) => [id, id in MANIFEST_TO_TOOL ? "1.0" : "99.0"]),
    ),
  };
}

let current: ReleaseView = releaseView(manifestFile);

export function getRelease(): ReleaseView {
  return current;
}

/** Tests: use another manifest (the next test starts from all tools again). */
export function useManifest(manifest: ReleaseManifest): void {
  current = releaseView(manifest);
}

/** Tests: back to the shipped manifest. */
export function resetRelease(): void {
  current = releaseView(manifestFile);
}

export const releasedTools = (): Tool[] => current.released;

export const isToolReleased = (tool: Tool): boolean => current.released.includes(tool);

/** The release [tool] ships in, e.g. "1.2". */
export const toolVersion = (tool: Tool): string | undefined => current.versions[tool];
