const { api } = require('./support/api');
const { expect } = require('chai');

/*
 * US-PROMO-04: test/paddle.test.js swaps in a fake client, which proves the
 * controller hands a discount id down. This file uses the real client with
 * fetch stubbed, so it proves the id actually goes on the wire as
 * `discount_id` — and that an ordinary checkout still sends no such field.
 */

const realFetch = global.fetch;
let sent = [];

function stubFetch() {
  sent = [];
  global.fetch = async (url, init) => {
    sent.push({ url: String(url), method: init.method, body: JSON.parse(init.body) });
    return { ok: true, json: async () => ({ data: { id: 'txn_123' } }) };
  };
}

function enablePaddle() {
  process.env.BILLING_ENABLED = 'true';
  process.env.PADDLE_API_KEY = 'pdl_sdbx_test';
  process.env.PADDLE_WEBHOOK_SECRET = 'whsec_test';
  process.env.PADDLE_PRICE_MONTHLY = 'pri_monthly';
  process.env.PADDLE_PRICE_YEARLY = 'pri_yearly';
}

let counter = 0;
async function signup() {
  counter += 1;
  const email = `paddleclient${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  return { id: res.body.user._id, token: res.body.token ?? res.body.accessToken };
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

// Hooks live inside the describe: a top-level afterEach in mocha is a root
// hook and would run after every test in the run, blanking the environment
// other suites rely on.
describe('Paddle client transactions (US-PROMO-04)', function() {
  beforeEach(function() {
    enablePaddle();
    stubFetch();
  });

  afterEach(function() {
    global.fetch = realFetch;
    for (const name of [
      'BILLING_ENABLED', 'PADDLE_API_KEY', 'PADDLE_WEBHOOK_SECRET',
      'PADDLE_PRICE_MONTHLY', 'PADDLE_PRICE_YEARLY', 'PROMO_CODES',
    ]) {
      process.env[name] = '';
    }
  });

  it('sends discount_id on the transaction when a discount code is used', async function() {
    process.env.PROMO_CODES = JSON.stringify([
      { code: 'SAVE20', discountId: 'dsc_0123456789abcdef' },
    ]);
    const me = await signup();

    const res = await authed('post', '/api/billing/paddle/checkout', me.token)
      .send({ interval: 'yearly', code: 'save20' });

    expect(res.status).to.equal(200);
    expect(sent).to.have.length(1);
    expect(sent[0]).to.include({ url: 'https://sandbox-api.paddle.com/transactions', method: 'POST' });
    expect(sent[0].body).to.deep.equal({
      items: [{ price_id: 'pri_yearly', quantity: 1 }],
      discount_id: 'dsc_0123456789abcdef',
      custom_data: { userId: String(me.id) },
    });
  });

  it('sends no discount_id without a code, so an ordinary checkout is unchanged', async function() {
    const me = await signup();

    const res = await authed('post', '/api/billing/paddle/checkout', me.token)
      .send({ interval: 'monthly' });

    expect(res.status).to.equal(200);
    expect(sent[0].body).to.deep.equal({
      items: [{ price_id: 'pri_monthly', quantity: 1 }],
      custom_data: { userId: String(me.id) },
    });
  });
});
