const { expect } = require('chai');
const User = require('../models/User');
const Subscription = require('../models/Subscription');
const { ensureTestAccounts, TESTER, OLD_EMAIL } = require('../scripts/ensure-test-accounts');

describe('Tester account setup (release 1.0.0)', function() {
  it('creates the documented free tester and removes the old account and plan', async function() {
    const old = new User({ email: OLD_EMAIL, password: 'password' });
    await old.save();
    await Subscription.create({
      userId: old._id,
      plan: 'pro',
      status: 'active',
      source: 'admin',
      grant: { plan: 'pro', status: 'active', source: 'admin', willRenew: false },
    });

    await ensureTestAccounts();

    expect(await User.exists({ email: OLD_EMAIL })).to.equal(null);
    expect(await Subscription.exists({ userId: old._id })).to.equal(null);

    const tester = await User.findOne({ email: TESTER.email });
    expect(tester).to.not.equal(null);
    expect(await tester.comparePassword(TESTER.password)).to.equal(true);
    // Free: no Subscription document at all, so billing's default applies.
    expect(await Subscription.exists({ userId: tester._id })).to.equal(null);
  });

  it('is idempotent and resets the documented password', async function() {
    await ensureTestAccounts();
    const first = await User.findOne({ email: TESTER.email });
    await ensureTestAccounts();
    const second = await User.findOne({ email: TESTER.email });

    expect(String(second._id)).to.equal(String(first._id));
    expect(await second.comparePassword(TESTER.password)).to.equal(true);
    expect(await Subscription.exists({ userId: second._id })).to.equal(null);
  });
});
