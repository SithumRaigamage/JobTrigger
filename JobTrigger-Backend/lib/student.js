/**
 * Phase 21: the small shared pieces of the student plan: the allowed
 * university domains (SP-13), the hashes that make a grant one-per-person
 * (SP-14), and the grant itself (SP-10).
 */
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const StudentClaim = require('../models/StudentClaim');
const { blindIndex } = require('../security/blindIndex');
const { writeSource } = require('../billing/combine');

const GRANT_DAYS = 365;
const DAY_MS = 24 * 60 * 60 * 1000;
const DOMAINS_FILE = path.join(__dirname, '..', 'config', 'studentDomains.json');

const sha256 = (value) => crypto.createHash('sha256').update(value).digest('hex');

/**
 * The hash kept for [email] (trimmed, lowercased). NFR-SEC-08 AC5: keyed
 * (security/blindIndex.js), so a leaked claim can't be reversed by hashing
 * guessed emails. `legacyEmailHash` is the old plain form, kept only for
 * the backfill that converts existing claims.
 */
const normalizeStudentEmail = (email) => String(email).trim().toLowerCase();
const emailHash = (email) => blindIndex('student-email', normalizeStudentEmail(email));
const legacyEmailHash = (email) => sha256(`student-email:${normalizeStudentEmail(email)}`);

/** The hash kept for the document's raw [bytes]. */
const documentHash = (bytes) => sha256(bytes);

let domainsOverride = null;
/** Tests: a list of domains, or null to read the file again. */
function setDomainsForTests(list) {
  domainsOverride = list;
}

/** The listed domains, read from the owner-editable file each time. */
function allowedDomains() {
  if (domainsOverride) return domainsOverride;
  const parsed = JSON.parse(fs.readFileSync(DOMAINS_FILE, 'utf8'));
  return (parsed.domains ?? []).map((d) => String(d).trim().toLowerCase()).filter(Boolean);
}

/** True when [email]'s domain is a listed domain or a subdomain of one. */
function isListedUniversityEmail(email) {
  const domain = String(email).trim().toLowerCase().split('@')[1];
  if (!domain) return false;
  return allowedDomains().some((d) => domain === d || domain.endsWith(`.${d}`));
}

/** Whether a claim for this [kind] and [hash] already exists. */
async function isClaimed(kind, hash) {
  return Boolean(await StudentClaim.exists({ kind, hash }));
}

/**
 * Claims [hash] for good. Returns false when someone already holds it
 * (the unique index decides, so this is safe under concurrency).
 */
async function claim(kind, hash) {
  try {
    await StudentClaim.create({ kind, hash });
    return true;
  } catch (err) {
    if (err?.code === 11000) return false;
    throw err;
  }
}

/** Gives the user a year of Pro from [now] (SP-10). Returns the end date. */
async function grantStudentYear(userId, now = new Date()) {
  const expiresAt = new Date(now.getTime() + GRANT_DAYS * DAY_MS);
  await writeSource(userId, 'student', {
    plan: 'pro',
    status: 'active',
    source: 'student',
    productId: null,
    startsAt: now,
    periodEnd: expiresAt,
    willRenew: false,
  }, { now });
  return expiresAt;
}

module.exports = {
  legacyEmailHash,
  GRANT_DAYS,
  DAY_MS,
  allowedDomains,
  claim,
  documentHash,
  emailHash,
  grantStudentYear,
  isClaimed,
  isListedUniversityEmail,
  setDomainsForTests,
  sha256,
};
