// Run with: node --test scripts/
//
// The release build script injects secrets at build time. These tests use a
// fixture app directory and a fake `flutter` that copies the merged define
// file, so they never touch the real config or run a build.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

const SCRIPT = resolve("scripts/build-release.sh");

const sentinels = {
  envDsn: "https://env@secret.invalid/1",
  fileDsn: "https://file@secret.invalid/2",
  iosKey: "appl_secret_env",
  androidKey: "goog_secret_file",
};

/** A fixture app with a base config plus a fake Flutter that records its input. */
function fixture(t) {
  const dir = mkdtempSync(join(tmpdir(), "jobtrigger-release-test-"));
  t.after(() => rmSync(dir, { recursive: true, force: true }));

  const config = join(dir, "config");
  mkdirSync(config, { recursive: true });

  writeFileSync(
    join(config, "prod.json"),
    JSON.stringify({
      ENVIRONMENT: "prod",
      BACKEND_BASE_URL: "https://api.example.invalid",
      WEBSITE_BASE_URL: "https://example.invalid",
    }),
  );

  const fakeFlutter = join(dir, "fake-flutter");
  writeFileSync(
    fakeFlutter,
    `#!/usr/bin/env bash
set -euo pipefail
for arg in "$@"; do
  case "$arg" in
    --dart-define-from-file=*)
      cp "\${arg#*=}" "$FAKE_DEFINES"
      printf '%s\\n' "\${arg#*=}" > "$FAKE_SOURCE"
      ;;
  esac
done
printf '%s\\n' "$*" > "$FAKE_LOG"
`,
  );
  chmodSync(fakeFlutter, 0o755);

  return {
    dir,
    config,
    fakeFlutter,
    defines: join(dir, "merged.json"),
    source: join(dir, "source-path"),
    log: join(dir, "flutter.log"),
  };
}

function run(fx, args, extraEnv = {}) {
  const env = { ...process.env, JOBTRIGGER_APP_DIR: fx.dir, FLUTTER: fx.fakeFlutter };
  for (const name of [
    "SENTRY_DSN",
    "SENTRY_DSN_APP",
    "REVENUECAT_IOS_KEY",
    "REVENUECAT_ANDROID_KEY",
  ]) {
    delete env[name];
  }
  Object.assign(env, extraEnv);
  env.FAKE_DEFINES = fx.defines;
  env.FAKE_SOURCE = fx.source;
  env.FAKE_LOG = fx.log;

  return spawnSync("bash", [SCRIPT, ...args], { env, encoding: "utf8" });
}

function writeSecrets(fx) {
  writeFileSync(
    join(fx.config, "sentry.json"),
    JSON.stringify({ SENTRY_DSN: sentinels.fileDsn }),
  );
  writeFileSync(
    join(fx.config, "billing.json"),
    JSON.stringify({ REVENUECAT_ANDROID_KEY: sentinels.androidKey }),
  );
}

test("merges base config, secret files and the environment, env winning", (t) => {
  const fx = fixture(t);
  writeSecrets(fx);

  const result = run(fx, ["ipa"], {
    SENTRY_DSN: sentinels.envDsn,
    REVENUECAT_IOS_KEY: sentinels.iosKey,
  });

  assert.equal(result.status, 0, result.stderr);
  const merged = JSON.parse(readFileSync(fx.defines, "utf8"));
  assert.equal(merged.ENVIRONMENT, "prod");
  assert.equal(merged.WEBSITE_BASE_URL, "https://example.invalid");
  // The environment overrides the file; the file supplies what it alone has.
  assert.equal(merged.SENTRY_DSN, sentinels.envDsn);
  assert.equal(merged.REVENUECAT_IOS_KEY, sentinels.iosKey);
  assert.equal(merged.REVENUECAT_ANDROID_KEY, sentinels.androidKey);

  // The temporary define file is removed after the build.
  const definePath = readFileSync(fx.source, "utf8").trim();
  assert.notEqual(definePath, "");
  assert.equal(existsSync(definePath), false);
});

test("prints key names but never a secret value", (t) => {
  const fx = fixture(t);
  writeSecrets(fx);

  const result = run(fx, ["--check", "ipa"], {
    SENTRY_DSN: sentinels.envDsn,
    REVENUECAT_IOS_KEY: sentinels.iosKey,
  });

  assert.equal(result.status, 0, result.stderr);
  const output = result.stdout + result.stderr;
  assert.match(output, /SENTRY_DSN/);
  for (const secret of Object.values(sentinels)) {
    assert.equal(output.includes(secret), false, `printed ${secret}`);
  }
});

test("fails when a required key is missing, and names it", (t) => {
  const fx = fixture(t);

  const result = run(fx, ["--check", "apk"]);

  assert.equal(result.status, 1);
  assert.match(result.stderr, /Missing for release target 'apk'/);
  assert.match(result.stderr, /SENTRY_DSN/);
  assert.match(result.stderr, /REVENUECAT_ANDROID_KEY/);
  // Nothing was built.
  assert.equal(existsSync(fx.log), false);
});

test("--check validates without invoking the build", (t) => {
  const fx = fixture(t);
  writeSecrets(fx);

  const result = run(fx, ["--check", "appbundle"]);

  assert.equal(result.status, 0, result.stderr);
  assert.equal(existsSync(fx.log), false);
});

test("--allow-missing builds, but warns about what is off", (t) => {
  const fx = fixture(t);

  const result = run(fx, ["--allow-missing", "apk"]);

  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stderr, /--allow-missing/);
  assert.equal(existsSync(fx.log), true);
});

test("rejects an unknown target and a dev environment", (t) => {
  const fx = fixture(t);

  assert.equal(run(fx, ["--check", "windows"]).status, 1);
  assert.equal(run(fx, ["--check", "--env=dev", "apk"]).status, 1);
  assert.equal(run(fx, ["--check", "--no-codesign", "apk"]).status, 1);
});

test("--no-codesign reaches the iOS build, for CI verification", (t) => {
  const fx = fixture(t);

  const result = run(fx, ["--allow-missing", "--no-codesign", "ipa"]);

  assert.equal(result.status, 0, result.stderr);
  assert.match(readFileSync(fx.log, "utf8"), /build ipa --release --no-codesign/);
});

test("refuses a development-lab DSN or address, even with --allow-missing", (t) => {
  // Pre-release audit 2026-11-20: config/sentry.json also holds the lab
  // GlitchTip DSN for iPhone runs, so a store build must reject it.
  const devValues = [
    "http://key@192.168.1.53:8000/1",
    "https://key@Sithums-MacBook-Pro.local:8000/1",
    "https://key@localhost/1",
    "https://key@10.0.2.2/1",
    "https://key@172.20.0.4/1",
    "https://key@glitchtip/1",
  ];
  for (const dsn of devValues) {
    const fx = fixture(t);
    const result = run(fx, ["--allow-missing", "apk"], { SENTRY_DSN: dsn });

    assert.equal(result.status, 1, `accepted ${dsn}`);
    assert.match(result.stderr, /Not a release address/);
    assert.match(result.stderr, /SENTRY_DSN/);
    // The value itself is never printed.
    assert.equal(result.stderr.includes(dsn), false);
    assert.equal(existsSync(fx.log), false, `built with ${dsn}`);
  }
});

test("refuses an http:// or LAN backend in the base config", (t) => {
  const fx = fixture(t);
  writeFileSync(
    join(fx.config, "prod.json"),
    JSON.stringify({
      ENVIRONMENT: "prod",
      BACKEND_BASE_URL: "http://192.168.1.53:5001",
      WEBSITE_BASE_URL: "https://example.invalid",
    }),
  );

  const result = run(fx, ["--allow-missing", "apk"]);

  assert.equal(result.status, 1);
  assert.match(result.stderr, /BACKEND_BASE_URL/);
  assert.equal(result.stderr.includes("WEBSITE_BASE_URL"), false);
});
