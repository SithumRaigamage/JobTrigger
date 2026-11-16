/**
 * Which tools this release supports: release/tools.json, copied to
 * config/tools.json by scripts/sync-tools.mjs. A credential can be created
 * only for a released tool; reads, updates and deletes are never blocked, so
 * what a user already saved is untouched.
 *
 * The manifest names GitHub Actions "githubActions"; this backend's tool,
 * routes and stored data call it "github". The mapping below is the only
 * place that knows both. Nothing is renamed.
 */
const manifestFile = require('../config/tools.json');

/** Manifest id -> this backend's tool name. */
const LOCAL_TOOL = Object.freeze({
  jenkins: 'jenkins',
  githubActions: 'github',
  sonarqube: 'sonarqube',
});

/** Planned in the manifest, no code here yet: never a local tool. */
const PLANNED_ONLY = Object.freeze(['gitlab', 'circleci']);

const VERSION = /^\d+\.\d+$/;

/** `1.10` is after `1.2`: numbers, not text. */
function compareVersions(a, b) {
  const [aMajor, aMinor] = a.split('.').map(Number);
  const [bMajor, bMinor] = b.split('.').map(Number);
  return aMajor - bMajor || aMinor - bMinor;
}

/**
 * The released local tools of [manifest]. Fails loudly (throws) on an id this
 * backend does not know, a bad version, or a released tool with no local
 * tool, so a typo or a half-added tool never silently opens or closes a door.
 */
function releasedLocalTools(manifest) {
  if (!manifest || !VERSION.test(manifest.release) || typeof manifest.tools !== 'object') {
    throw new Error('config/tools.json is not a release manifest');
  }
  const released = new Set();
  for (const [id, version] of Object.entries(manifest.tools)) {
    if (!VERSION.test(version)) throw new Error(`Tool "${id}": bad version ${JSON.stringify(version)}`);
    const local = LOCAL_TOOL[id];
    const isReleased = compareVersions(version, manifest.release) <= 0;
    if (local === undefined) {
      if (!PLANNED_ONLY.includes(id)) throw new Error(`Unknown tool "${id}" in config/tools.json`);
      if (isReleased) throw new Error(`Tool "${id}" is released but has no code here`);
      continue;
    }
    if (isReleased) released.add(local);
  }
  return released;
}

let released = releasedLocalTools(manifestFile);

/** Whether [tool] (a local name: jenkins, github, sonarqube) may be created. */
function isToolReleased(tool) {
  return released.has(tool);
}

/** Tests: use another manifest; returns the one to restore. */
function useManifest(manifest) {
  const previous = released;
  released = releasedLocalTools(manifest);
  return previous;
}

/** Tests: put back what [useManifest] returned. */
function restore(previous) {
  released = previous;
}

/** Tests: the shipped manifest with every tool that has code released. */
function allToolsManifest() {
  return {
    release: '98.0',
    tools: Object.fromEntries(
      Object.keys(manifestFile.tools).map((id) => [id, id in LOCAL_TOOL ? '1.0' : '99.0']),
    ),
  };
}

/** 403 body for creating a credential for an unreleased tool. */
const TOOL_NOT_AVAILABLE = Object.freeze({
  message: 'This tool is not available yet',
  code: 'TOOL_NOT_AVAILABLE',
});

module.exports = {
  LOCAL_TOOL,
  PLANNED_ONLY,
  TOOL_NOT_AVAILABLE,
  allToolsManifest,
  isToolReleased,
  releasedLocalTools,
  restore,
  useManifest,
};
