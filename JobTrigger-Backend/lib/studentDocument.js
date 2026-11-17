/**
 * Phase 21 (SP-30): checks an uploaded student document. The file arrives
 * as base64 in JSON (no upload library), so the server decodes it and
 * decides the type from the file's leading bytes, never from its name or
 * the type the client claims.
 */
const MAX_BYTES = 5 * 1024 * 1024;
const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;

const SIGNATURES = [
  { mime: 'image/jpeg', ext: 'jpg', test: (b) => b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff },
  {
    mime: 'image/png',
    ext: 'png',
    test: (b) => b.length > 8 && [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].every((v, i) => b[i] === v),
  },
  { mime: 'application/pdf', ext: 'pdf', test: (b) => b.length > 5 && b.subarray(0, 5).toString('latin1') === '%PDF-' },
];

const TOO_LARGE = 'File too large, max 5 MB';
const WRONG_TYPE = 'Only JPG, PNG or PDF files are accepted';

/**
 * Decodes [data] (base64). Returns `{ bytes, mime, ext }`, or
 * `{ error: { status, message } }`.
 */
function inspectDocument(data) {
  if (typeof data !== 'string' || !data) {
    return { error: { status: 400, message: 'Choose a file to upload' } };
  }
  // Size from the text first, so a huge string is never decoded.
  if (Math.floor((data.length * 3) / 4) > MAX_BYTES + 3) {
    return { error: { status: 413, message: TOO_LARGE } };
  }
  if (data.length % 4 !== 0 || !BASE64.test(data)) {
    return { error: { status: 400, message: 'The file could not be read' } };
  }
  const bytes = Buffer.from(data, 'base64');
  if (bytes.length > MAX_BYTES) return { error: { status: 413, message: TOO_LARGE } };
  const type = SIGNATURES.find((s) => s.test(bytes));
  if (!type) return { error: { status: 415, message: WRONG_TYPE } };
  return { bytes, mime: type.mime, ext: type.ext };
}

module.exports = { inspectDocument, MAX_BYTES, TOO_LARGE, WRONG_TYPE };
