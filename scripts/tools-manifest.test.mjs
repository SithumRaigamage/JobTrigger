// Run with: node --test scripts/
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { copies, drift, source } from "./sync-tools.mjs";
import { compareVersions, problems, releasedTools } from "./tools-manifest.mjs";

const valid = {
  release: "1.0",
  tools: { jenkins: "1.0", sonarqube: "1.1", githubActions: "1.2", gitlab: "1.3", circleci: "1.3" },
};

test("the committed manifest is valid and is release 1.0, Jenkins only", () => {
  const manifest = JSON.parse(readFileSync(source, "utf8"));
  assert.deepEqual(problems(manifest), []);
  assert.equal(manifest.release, "1.0");
  assert.deepEqual(releasedTools(manifest), ["jenkins"]);
  assert.deepEqual(manifest.tools, valid.tools);
});

test("every copy matches release/tools.json", () => {
  assert.deepEqual(drift(), []);
});

test("a copy that differs or is missing is reported", () => {
  const dir = mkdtempSync(join(tmpdir(), "tools-"));
  const same = join(dir, "same.json");
  const other = join(dir, "other.json");
  writeFileSync(same, readFileSync(source, "utf8"));
  writeFileSync(other, '{"release":"9.9","tools":{}}');
  assert.deepEqual(drift(source, [same, other, join(dir, "missing.json")]), [
    other,
    join(dir, "missing.json"),
  ]);
  assert.equal(copies.length, 3);
});

test("versions compare as numbers", () => {
  assert.ok(compareVersions("1.10", "1.2") > 0);
  assert.ok(compareVersions("1.0", "1.0") === 0);
  assert.ok(compareVersions("1.1", "2.0") < 0);
});

test("release 1.1 releases Jenkins and SonarQube; 1.2 adds GitHub Actions", () => {
  assert.deepEqual(releasedTools({ ...valid, release: "1.1" }), ["jenkins", "sonarqube"]);
  assert.deepEqual(releasedTools({ ...valid, release: "1.2" }), [
    "jenkins",
    "sonarqube",
    "githubActions",
  ]);
});

test("planned tools with no code yet are accepted while their release is ahead", () => {
  assert.deepEqual(problems(valid), []);
  assert.deepEqual(problems({ ...valid, release: "1.2" }), []);
});

test("a tool whose release has come but has no code is refused", () => {
  const found = problems({ ...valid, release: "1.3" });
  assert.equal(found.length, 2);
  assert.match(found[0], /"gitlab" is released in 1.3 but has no code yet/);
  assert.match(found[1], /"circleci" is released in 1.3 but has no code yet/);
});

test("malformed manifests are explained", () => {
  assert.match(problems({ release: "1", tools: valid.tools })[0], /"release" must look like/);
  assert.match(problems({ release: "1.0", tools: { jenkins: "one" } })[0], /version must look like/);
  assert.match(problems({ release: "1.0", tools: { "Bad-Id": "1.0" } })[0], /camelCase/);
  assert.match(problems({ release: "1.0", tools: {} }).join(" "), /must not be empty/);
  assert.match(problems({ release: "1.0", tools: { sonarqube: "1.1" } }).join(" "), /At least one tool/);
  assert.match(problems(null)[0], /must be an object/);
});
