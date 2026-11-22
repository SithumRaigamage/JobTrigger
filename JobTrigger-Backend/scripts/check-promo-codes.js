/**
 * US-PROMO-05: check `PROMO_CODES` before it goes into a deployment.
 *
 * A malformed list stops the backend from starting (deliberately — a code
 * list it can't understand should never be half-used), which means a typo in
 * the deployment's variables takes the whole API down. This runs the same
 * check locally, on the same config code the server uses, so the typo is
 * caught before the deploy instead of after it.
 *
 *   PROMO_CODES='[{"code":"LAUNCH30","days":30}]' npm run check-promo-codes
 *
 * Exits 0 when the value is usable (or unset), 1 with the sentence the server
 * would print when it isn't. Never prints a value from the list.
 */
const { promoCodeProblems, promoCodes } = require('../config/env');

/** The verdict for [raw]: `{ ok, problem }` or `{ ok, total, proTime, checkout }`. */
function check(raw) {
  const env = { ...process.env, PROMO_CODES: raw ?? '' };
  const problem = promoCodeProblems(env);
  if (problem) return { ok: false, problem };
  const codes = promoCodes(env);
  return {
    ok: true,
    total: codes.length,
    proTime: codes.filter((entry) => entry.days).length,
    checkout: codes.filter((entry) => entry.discountId).length,
  };
}

function main() {
  const result = check(process.env.PROMO_CODES);
  if (!result.ok) {
    console.error(`PROMO_CODES is not usable, so the server would refuse to start: ${result.problem}`);
    process.exitCode = 1;
    return;
  }
  if (result.total === 0) {
    console.log('PROMO_CODES is not set: promo codes are off.');
    return;
  }
  console.log(
    `PROMO_CODES is usable: ${result.total} code(s) — ${result.proTime} for Pro time, `
    + `${result.checkout} for the checkout.`,
  );
}

if (require.main === module) main();

module.exports = { check };
