/**
 * AUD-66: the repository must not carry live credential material.
 *
 * A Jenkins API token sat in this repository's public history (the
 * SwiftUI-era `jenkins_credentials.json`), and a second one in a curl
 * example. Both files are gone from the tree, and gitleaks scans the
 * whole history on every push -- but gitleaks is a separate binary in a
 * separate workflow: if that scan is ever mis-scoped or skipped, nothing
 * in the test suite would notice a credential being committed.
 *
 * This module is the in-suite guard. It walks the tracked tree and looks
 * for the shape that actually matters:
 *
 *   token-literal      a Jenkins-token-shaped value anywhere in a file
 *   credential-value   a credential-shaped key bound to such a value
 *   basic-auth-header  a token-shaped part inside a Basic Authorization
 *   bearer-token       a token-shaped Bearer Authorization
 *
 * The rules are deliberately narrow. The tree is full of 40-character
 * git SHAs (Riverpod provider hashes, pub lock hashes, pinned action
 * digests) and a blanket "32 hex characters" rule would be pure noise --
 * so a token shape must not be part of a longer hex string, and a
 * credential must be bound to a credential-shaped key.
 *
 * The one place a token-shaped literal may live is the reviewed
 * allowlist at the repository root, which mirrors `.gitleaksignore`:
 * one path per line, with a reason, and only for a value that is not a
 * live secret. A finding names the file, the line and the rule; the
 * value is never returned, so a failure message cannot leak what it
 * found.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

// A Jenkins credential value: 32 hex characters (legacy) or the modern
// 11-prefixed form -- the same shape `looksLikeJenkinsApiToken` uses in
// the app. The lookarounds keep a 40-character git SHA from matching:
// only a value that is *not* part of a longer hex string is a token.
const TOKEN_SHAPE = /(?<![0-9a-f])((?:11)?[0-9a-f]{32})(?![0-9a-f])/g;

// The same shape, anchored, for a whole value.
const TOKEN_VALUE = /^(11)?[0-9a-f]{32}$/;

// Keys whose value is a credential. Compared after normalising the key
// (lower-cased, non-letters removed), so `apiToken`, `api_token` and
// `API-TOKEN` are all the same key.
const CREDENTIAL_KEYS = new Set([
  'password',
  'passwd',
  'pass',
  'token',
  'apitoken',
  'accesstoken',
  'authtoken',
  'bearertoken',
  'jenkinstoken',
  'personalaccesstoken',
  'pat',
  'secret',
  'paramtoken',
  'credential',
  'credentials',
  'auth',
  'authorization',
  'apikey',
  'apisecret',
  'privatekey',
]);

// `key: "value"`, `key = "value"`, `'key': "value"`.
const KEY_VALUE = /["']?([A-Za-z_][A-Za-z0-9_.-]*)["']?\s*[:=]\s*["']([^"'\n]+)["']/g;

// `Authorization: Basic <base64>`.
const BASIC_HEADER = /Basic\s+([A-Za-z0-9+/]{12,}={0,2})/g;

// `Authorization: Bearer <token>`.
const BEARER_HEADER = /Bearer\s+([A-Za-z0-9._-]{16,})/g;

/**
 * Paths this scan never reads.
 *
 * Env files are excluded by policy: `CLAUDE.md` §8 forbids reading
 * `.env` files, and they are configuration, not source. gitleaks still
 * scans them as part of the history, so nothing is lost.
 *
 * The rest are build output and vendored dependencies -- not tracked
 * content, and enormous.
 */
function isSkippedPath(relativePath) {
  return (
    /(^|\/)\.env(\.|$)/i.test(relativePath) ||
    /(^|\/)(node_modules|\.git|build|\.dart_tool|Pods|\.symlinks|coverage)(\/|$)/.test(
      relativePath,
    )
  );
}

function normaliseKey(key) {
  return key.toLowerCase().replace(/[^a-z]/g, '');
}

/**
 * The tracked files of the repository, relative to [root].
 *
 * `git ls-files` is the source of truth: it is exactly what would be
 * committed, and it skips build output and dependencies for free. When
 * the tree is not a git checkout (a source tarball, say) the tree is
 * walked instead.
 */
function listTrackedFiles(root) {
  try {
    const out = execFileSync('git', ['ls-files', '-z'], {
      cwd: root,
      encoding: 'utf8',
      maxBuffer: 64 * 1024 * 1024,
    });
    const files = out.split('\0').filter(Boolean);
    if (files.length > 0) return files;
  } catch {
    // Not a git checkout, or git is unavailable. Fall through.
  }
  return walkTree(root, root);
}

function walkTree(root, current) {
  const found = [];
  for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
    const absolute = path.join(current, entry.name);
    const relative = path.relative(root, absolute).split(path.sep).join('/');
    if (isSkippedPath(relative)) continue;
    if (entry.isDirectory()) {
      found.push(...walkTree(root, absolute));
    } else if (entry.isFile()) {
      found.push(relative);
    }
  }
  return found;
}

/**
 * Read the reviewed allowlist: one repository-relative path per line,
 * `#` comments allowed.
 *
 * @returns {string[]} the allowed paths.
 */
function readAllowlist(root, fileName = '.secret-material-allowlist') {
  const absolute = path.join(root, fileName);
  let text;
  try {
    text = fs.readFileSync(absolute, 'utf8');
  } catch {
    return [];
  }
  return text
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'));
}

/**
 * Every credential-shaped value in [text].
 *
 * @param {string} text the file contents.
 * @param {string} relativePath the file's path, for the finding.
 * @param {boolean} literalAllowed true when the file is on the
 *   allowlist, which waives the bare-literal rule.
 * @returns {Array<{rule: string, file: string, line: number, key: string}>}
 *   The offending line, never the value itself.
 */
function findSecretMaterial(text, relativePath, literalAllowed = false) {
  const findings = [];

  text.split('\n').forEach((line, index) => {
    if (!literalAllowed) {
      TOKEN_SHAPE.lastIndex = 0;
      let literal;
      while ((literal = TOKEN_SHAPE.exec(line)) !== null) {
        findings.push({
          rule: 'token-literal',
          file: relativePath,
          line: index + 1,
          key: 'literal',
        });
      }
    }

    KEY_VALUE.lastIndex = 0;
    let match;
    while ((match = KEY_VALUE.exec(line)) !== null) {
      const [, key, value] = match;
      if (CREDENTIAL_KEYS.has(normaliseKey(key)) && TOKEN_VALUE.test(value.trim())) {
        findings.push({
          rule: 'credential-value',
          file: relativePath,
          line: index + 1,
          key: normaliseKey(key),
        });
      }
    }

    BASIC_HEADER.lastIndex = 0;
    while ((match = BASIC_HEADER.exec(line)) !== null) {
      let decoded = '';
      try {
        decoded = Buffer.from(match[1], 'base64').toString('utf8');
      } catch {
        decoded = '';
      }
      const parts = decoded.split(':');
      if (
        parts.length === 2 &&
        (TOKEN_VALUE.test(parts[0].trim()) || TOKEN_VALUE.test(parts[1].trim()))
      ) {
        findings.push({
          rule: 'basic-auth-header',
          file: relativePath,
          line: index + 1,
          key: 'authorization',
        });
      }
    }

    BEARER_HEADER.lastIndex = 0;
    while ((match = BEARER_HEADER.exec(line)) !== null) {
      if (TOKEN_VALUE.test(match[1].trim())) {
        findings.push({
          rule: 'bearer-token',
          file: relativePath,
          line: index + 1,
          key: 'authorization',
        });
      }
    }
  });

  return findings;
}

/**
 * Scan the repository at [root] for credential material.
 *
 * @param {string} root the repository root.
 * @param {string[]} [allowlist] paths whose token-shaped literals are
 *   reviewed and accepted.
 * @returns {Array<{rule: string, file: string, line: number, key: string}>}
 */
function scanRepository(root, allowlist) {
  const allowed = new Set(allowlist || readAllowlist(root));
  const findings = [];
  for (const relative of listTrackedFiles(root)) {
    if (isSkippedPath(relative)) continue;
    const absolute = path.join(root, relative);
    let text;
    try {
      const buffer = fs.readFileSync(absolute);
      // Binary: nothing to read a credential out of.
      if (buffer.includes(0)) continue;
      text = buffer.toString('utf8');
    } catch {
      continue;
    }
    findings.push(...findSecretMaterial(text, relative, allowed.has(relative)));
  }
  return findings;
}

module.exports = {
  findSecretMaterial,
  listTrackedFiles,
  normaliseKey,
  readAllowlist,
  scanRepository,
  TOKEN_VALUE,
};
