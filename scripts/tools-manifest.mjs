// The release manifest's rules (release/tools.json), shared by the sync
// script and its tests. No dependencies: runs on any Node in CI.

/** Tools with code in the app, website and backend today. */
export const IMPLEMENTED = ["jenkins", "sonarqube", "githubActions"];

const VERSION = /^\d+\.\d+$/;
const TOOL_ID = /^[a-z][A-Za-z0-9]*$/;

/** Compares "1.10" and "1.2" as numbers, not text: negative, 0 or positive. */
export function compareVersions(a, b) {
  const [aMajor, aMinor] = a.split(".").map(Number);
  const [bMajor, bMinor] = b.split(".").map(Number);
  return aMajor - bMajor || aMinor - bMinor;
}

/**
 * Every problem with [manifest], as sentences; empty when it's valid.
 *
 * A tool that is planned but has no code yet (gitlab, circleci) is fine as
 * long as its release is still ahead: it only appears under "Coming next".
 * A tool whose release has come must have code, because the apps would
 * otherwise let a user select something that does not exist.
 */
export function problems(manifest) {
  const found = [];
  if (typeof manifest !== "object" || manifest === null) return ["The manifest must be an object."];
  const { release, tools } = manifest;
  if (typeof release !== "string" || !VERSION.test(release)) {
    found.push(`"release" must look like "1.0", not ${JSON.stringify(release)}.`);
  }
  if (typeof tools !== "object" || tools === null || Array.isArray(tools)) {
    found.push('"tools" must be an object of tool id to version.');
    return found;
  }
  const entries = Object.entries(tools);
  if (entries.length === 0) found.push('"tools" must not be empty.');
  for (const [id, version] of entries) {
    if (!TOOL_ID.test(id)) found.push(`Tool id ${JSON.stringify(id)} must be camelCase.`);
    if (typeof version !== "string" || !VERSION.test(version)) {
      found.push(`Tool "${id}": version must look like "1.1", not ${JSON.stringify(version)}.`);
      continue;
    }
    const released = VERSION.test(release ?? "") && compareVersions(version, release) <= 0;
    if (released && !IMPLEMENTED.includes(id)) {
      found.push(`Tool "${id}" is released in ${version} but has no code yet.`);
    }
  }
  if (!entries.some(([, version]) => VERSION.test(version ?? "") && VERSION.test(release ?? "") && compareVersions(version, release) <= 0)) {
    found.push("At least one tool must be released in the current release.");
  }
  return found;
}

/** The tools whose release has come, in manifest order. */
export function releasedTools(manifest) {
  return Object.entries(manifest.tools)
    .filter(([, version]) => compareVersions(version, manifest.release) <= 0)
    .map(([id]) => id);
}
