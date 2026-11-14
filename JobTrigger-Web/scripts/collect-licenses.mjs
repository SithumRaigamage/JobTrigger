// `npm run licenses`: rebuilds src/content/open-source-licenses.json, the data
// behind the website's /licenses page (PE-03). It lists the direct runtime
// dependencies of the app (JobTrigger-Frontend), this website and the backend,
// with the licence each declares. Run it after adding or upgrading a package.
//
// - npm packages: the `license` field of node_modules/<name>/package.json.
// - Flutter packages: the LICENSE file in the pub cache (found through
//   .dart_tool/package_config.json, so run `flutter pub get` first). A licence
//   it can't recognise is written as null, and the page links to pub.dev.
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const web = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repo = resolve(web, "..");
const out = join(web, "src/content/open-source-licenses.json");

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

function npmPackages(project) {
  const deps = Object.keys(readJson(join(project, "package.json")).dependencies ?? {});
  return deps.sort().map((name) => {
    const manifest = join(project, "node_modules", name, "package.json");
    const pkg = existsSync(manifest) ? readJson(manifest) : {};
    return {
      name,
      version: pkg.version ?? null,
      license: typeof pkg.license === "string" ? pkg.license : null,
      url: `https://www.npmjs.com/package/${name}`,
    };
  });
}

// Plain-text matching of the licence texts pub packages ship with. Line
// breaks and runs of spaces are collapsed first: the texts are wrapped at
// different widths, so "free of\ncharge" must still match.
function detectLicense(raw) {
  const text = raw.replace(/\s+/g, " ");
  if (/Apache License,? Version 2\.0/i.test(text)) return "Apache-2.0";
  if (/Permission is hereby granted, free of charge/i.test(text)) return "MIT";
  if (/Redistribution and use in source and binary forms/i.test(text)) {
    return /Neither the name/i.test(text) ? "BSD-3-Clause" : "BSD-2-Clause";
  }
  if (/Mozilla Public License,? v(ersion)?\.? ?2\.0/i.test(text)) return "MPL-2.0";
  if (/Permission to use, copy, modify, and\/or distribute this software/i.test(text)) return "ISC";
  if (/CC0 1\.0 Universal|Creative Commons Zero|Statement of Purpose The laws of most jurisdictions/i.test(text)) return "CC0-1.0";
  return null;
}

function directPubDeps(pubspec) {
  const lines = readFileSync(pubspec, "utf8").split("\n");
  const start = lines.findIndex((line) => line.trim() === "dependencies:");
  const names = [];
  for (const line of lines.slice(start + 1)) {
    if (/^\S/.test(line)) break; // next top-level section
    const match = /^  ([a-z0-9_]+):/.exec(line);
    if (match && match[1] !== "flutter") names.push(match[1]);
  }
  return names.sort();
}

function pubVersions(lockfile) {
  const versions = {};
  let current = null;
  for (const line of readFileSync(lockfile, "utf8").split("\n")) {
    const name = /^  ([a-z0-9_]+):$/.exec(line);
    if (name) current = name[1];
    const version = /^    version: "(.+)"$/.exec(line);
    if (version && current) versions[current] = version[1];
  }
  return versions;
}

function flutterPackages(project) {
  const config = join(project, ".dart_tool/package_config.json");
  const roots = existsSync(config)
    ? Object.fromEntries(readJson(config).packages.map((p) => [p.name, p.rootUri]))
    : {};
  const versions = pubVersions(join(project, "pubspec.lock"));
  return directPubDeps(join(project, "pubspec.yaml")).map((name) => {
    let license = null;
    const root = roots[name];
    if (root?.startsWith("file://")) {
      const dir = fileURLToPath(root);
      const file = ["LICENSE", "LICENSE.md", "LICENSE.txt", "LICENCE"]
        .map((name) => join(dir, name))
        .find((path) => existsSync(path));
      if (file) license = detectLicense(readFileSync(file, "utf8"));
    }
    return {
      name,
      version: versions[name] ?? null,
      license,
      url: `https://pub.dev/packages/${name}/license`,
    };
  });
}

const data = {
  app: flutterPackages(join(repo, "JobTrigger-Frontend")),
  website: npmPackages(web),
  backend: npmPackages(join(repo, "JobTrigger-Backend")),
};
writeFileSync(out, `${JSON.stringify(data, null, 2)}\n`);

const unknown = Object.values(data)
  .flat()
  .filter((p) => !p.license)
  .map((p) => p.name);
console.log(`Wrote ${out}`);
if (unknown.length) console.log(`Licence not recognised (page links to the registry): ${unknown.join(", ")}`);
