const { execFileSync } = require('child_process');
const path = require('path');
const { expect } = require('chai');

const { check } = require('../scripts/check-promo-codes');

const script = path.join(__dirname, '..', 'scripts', 'check-promo-codes.js');

/** Runs the script the way a deploy check would; returns its exit code and output. */
function run(raw) {
  try {
    const stdout = execFileSync(process.execPath, [script], {
      env: { ...process.env, PROMO_CODES: raw },
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return { status: 0, output: stdout };
  } catch (err) {
    return { status: err.status, output: `${err.stdout ?? ''}${err.stderr ?? ''}` };
  }
}

describe('check-promo-codes before a deploy (US-PROMO-05)', function() {
  it('passes a usable list and says how many of each kind, never the codes', function() {
    const result = run(JSON.stringify([
      { code: 'LAUNCH30', days: 30 },
      { code: 'SAVE20', discountId: 'dsc_0123456789abcdef' },
    ]));

    expect(result.status).to.equal(0);
    expect(result.output).to.include('2 code(s)');
    expect(result.output).to.include('1 for Pro time');
    expect(result.output).to.include('1 for the checkout');
    expect(result.output).to.not.include('LAUNCH30');
  });

  it('fails a typo the server would refuse to start on, naming only the variable', function() {
    const result = run('[{"code":"LAUNCH30","days":30},]');

    expect(result.status).to.equal(1);
    expect(result.output).to.include('PROMO_CODES');
    expect(result.output).to.include('refuse to start');
    expect(result.output).to.not.include('days":30},]');
  });

  it('is a pass, not a failure, when no codes are configured', function() {
    const result = run('');

    expect(result.status).to.equal(0);
    expect(result.output).to.include('off');
  });

  it('uses the same rules as the server', function() {
    // "OK" is only two characters; both kinds at once is refused.
    expect(check('[{"code":"OK","days":1}]')).to.include({ ok: false });
    expect(check('[{"code":"SAVE20","days":3,"discountId":"dsc_abc123"}]')).to.include({ ok: false });
    expect(check('[{"code":"SAVE20","discountId":"dsc_abc123"}]')).to.deep.include({
      ok: true, total: 1, proTime: 0, checkout: 1,
    });
  });
});
