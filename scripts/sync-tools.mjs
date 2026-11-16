#!/usr/bin/env node
// Copies release/tools.json, the one answer to "which tools does this build
// support", into the app, the website and the backend.
//
//   node scripts/sync-tools.mjs          validate, then write the copies
//   node scripts/sync-tools.mjs --check  validate, and fail if any copy
//                                        differs (what CI runs)
//
// The copies are byte-identical, so a diff is a plain file comparison.
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

import { problems } from "./tools-manifest.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
export const source = join(root, "release", "tools.json");
export const copies = [
  join(root, "JobTrigger-Frontend", "config", "tools.json"),
  join(root, "JobTrigger-Web", "src", "content", "tools.json"),
  join(root, "JobTrigger-Backend", "config", "tools.json"),
];

/** The copies that are missing or differ from the source. */
export function drift(sourcePath = source, copyPaths = copies) {
  const expected = readFileSync(sourcePath, "utf8");
  return copyPaths.filter(
    (path) => !existsSync(path) || readFileSync(path, "utf8") !== expected,
  );
}

function main() {
  const check = process.argv.includes("--check");
  const text = readFileSync(source, "utf8");
  let manifest;
  try {
    manifest = JSON.parse(text);
  } catch (error) {
    console.error(`release/tools.json is not valid JSON: ${error.message}`);
    process.exit(1);
  }
  const invalid = problems(manifest);
  if (invalid.length > 0) {
    console.error("release/tools.json is not valid:");
    for (const line of invalid) console.error(`  - ${line}`);
    process.exit(1);
  }

  if (check) {
    const stale = drift();
    if (stale.length > 0) {
      console.error("These copies differ from release/tools.json:");
      for (const path of stale) console.error(`  - ${relative(root, path)}`);
      console.error("Run: node scripts/sync-tools.mjs");
      process.exit(1);
    }
    console.log("release/tools.json: all copies match.");
    return;
  }

  for (const path of copies) {
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, text);
    console.log(`wrote ${relative(root, path)}`);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
