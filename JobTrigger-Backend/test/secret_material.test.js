const path = require('path');
const { expect } = require('chai');
const {
  findSecretMaterial,
  readAllowlist,
  scanRepository,
} = require('../security/secretMaterialScan');

// AUD-66: the repository must not carry live credential material.
describe('The repository carries no credential material (AUD-66)', function() {
  const REPO_ROOT = path.resolve(__dirname, '..', '..');

  // A synthetic token, assembled at runtime from short chunks so that no
  // token-shaped literal is ever written to this file -- the guard scans
  // the tree, and this file is part of the tree. The value is made up;
  // it authenticates nothing.
  const SAMPLE = ['a1b2c3d4', 'e5f60718', '2a3b4c5d', '6e7f8091'].join('');

  const findingsIn = (text, literalAllowed = false) =>
    findSecretMaterial(text, 'fixture.txt', literalAllowed);

  describe('the rules', function() {
    it('flags a token-shaped literal', function() {
      const findings = findingsIn(`const value = "${SAMPLE}";`);
      expect(findings).to.have.lengthOf(1);
      expect(findings[0].rule).to.equal('token-literal');
    });

    it('flags a credential-shaped key bound to a token', function() {
      const findings = findingsIn(`{"password": "${SAMPLE}"}`);
      expect(findings.map((f) => f.rule)).to.include('credential-value');
    });

    it('flags a Basic Authorization header carrying a token', function() {
      const header = 'Basic ' + Buffer.from('ci:' + SAMPLE).toString('base64');
      const findings = findingsIn(`Authorization: ${header}`);
      expect(findings.map((f) => f.rule)).to.include('basic-auth-header');
    });

    it('flags a Bearer Authorization carrying a token', function() {
      const findings = findingsIn(`Authorization: Bearer ${SAMPLE}`);
      expect(findings.map((f) => f.rule)).to.include('bearer-token');
    });

    it('does not flag a git SHA', function() {
      const sha = 'a'.repeat(40);
      expect(findingsIn(`const sha = "${sha}";`)).to.have.lengthOf(0);
    });

    it('does not flag an ordinary password', function() {
      expect(findingsIn('{"password": "hunter2"}')).to.have.lengthOf(0);
    });

    it('does not flag a pub lock hash', function() {
      const hash = 'f'.repeat(64);
      expect(findingsIn(`sha256: ${hash}`)).to.have.lengthOf(0);
    });

    it('never returns the value it found', function() {
      const findings = findingsIn(`{"password": "${SAMPLE}"}`);
      expect(JSON.stringify(findings)).to.not.include(SAMPLE);
    });
  });

  describe('the reviewed allowlist', function() {
    it('waives the literal rule for an allowlisted file', function() {
      const findings = findingsIn(`const value = "${SAMPLE}";`, true);
      expect(findings).to.have.lengthOf(0);
    });

    it('does not waive the credential-key rule', function() {
      const findings = findingsIn(`{"password": "${SAMPLE}"}`, true);
      expect(findings.map((f) => f.rule)).to.include('credential-value');
    });

    it('lists only files that exist', function() {
      const allowlist = readAllowlist(REPO_ROOT);
      expect(allowlist.length).to.be.greaterThan(0);
      for (const entry of allowlist) {
        expect(
          require('fs').existsSync(path.join(REPO_ROOT, entry)),
          `${entry} is on the allowlist but does not exist`,
        ).to.equal(true);
      }
    });
  });

  describe('the working tree', function() {
    it('carries no credential material', function() {
      const findings = scanRepository(REPO_ROOT);
      const described = findings
        .map((f) => `  ${f.file}:${f.line} (${f.rule})`)
        .join('\n');
      expect(
        findings,
        `credential material in the working tree:\n${described}\n` +
          'A real secret must be revoked, not just deleted. A synthetic ' +
          'fixture belongs in .secret-material-allowlist, with a reason.',
      ).to.have.lengthOf(0);
    });
  });
});
