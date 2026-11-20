const { api } = require('./support/api');
const { expect } = require('chai');
const student = require('../lib/student');

/**
 * Pre-release audit 2026-11-20: one account walked through every plan over
 * HTTP — Free, Pro (sandbox purchase), cancel and expiry back to Free with
 * the locked-server guard, the student year, and the year ending. Each rule
 * has its own focused test elsewhere; this proves they hold together.
 */
const DAY = 24 * 60 * 60 * 1000;
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

const plan = async (token) => (await authed('get', '/api/subscription', token)).body;
const jenkins = async (token) => (await authed('get', '/api/credentials', token)).body;
const github = async (token) => (await authed('get', '/api/github-credentials', token)).body;
const secret = (token, kind, id) => authed('get', `/api/${kind}/${id}/secret`, token);
const addJenkins = (token, name) => authed('post', '/api/credentials', token).send({
  serverName: name, jenkinsURL: `https://${name}.example.com`, username: 'u', password: `p-${name}`,
});
const addGitHub = (token) =>
  authed('post', '/api/github-credentials', token).send({ label: 'gh', token: 'ghp_journey' });

describe('Plan journey: Free → Pro → downgrade → Student → Free', function() {
  before(function() {
    process.env.BILLING_ENABLED = 'true';
    process.env.SANDBOX_BILLING = 'true';
  });
  after(function() {
    process.env.BILLING_ENABLED = '';
    process.env.SANDBOX_BILLING = '';
  });

  it('keeps every limit and the locked-server guard consistent end to end', async function() {
    const signup = await api().post('/api/auth/signup')
      .send({ email: 'journey@example.com', password: 'password' });
    const token = signup.body.token;
    const userId = signup.body.user._id;

    // Free: one server of any tool, the next is refused.
    expect((await plan(token)).plan).to.equal('free');
    const a = (await addJenkins(token, 'alpha')).body;
    const refused = await addGitHub(token);
    expect(refused.status).to.equal(403);
    expect(refused.body).to.include({ code: 'PLAN_LIMIT' });

    // Pro: buy monthly; every tool saves and every secret is readable.
    const bought = await authed('post', '/api/billing/sandbox/purchase', token).send({ period: 'monthly' });
    expect(bought.body).to.include({ plan: 'pro', status: 'active' });
    const b = (await addJenkins(token, 'beta')).body;
    const g = (await addGitHub(token)).body;
    expect(b._id).to.be.a('string');
    expect(g._id).to.be.a('string');
    expect([...(await jenkins(token)), ...(await github(token))].every((c) => !c.locked)).to.equal(true);
    expect((await secret(token, 'credentials', b._id)).body.password).to.equal('p-beta');

    // Cancel: still Pro until the period ends.
    const cancelled = await authed('post', '/api/billing/sandbox/cancel', token);
    expect(cancelled.body).to.include({ plan: 'pro', willRenew: false });
    expect((await secret(token, 'github-credentials', g._id)).status).to.equal(200);

    // Expired: Free again. Nothing is deleted, the oldest stays usable,
    // the rest are locked: no secret, cannot be made active.
    const expired = await authed('post', '/api/billing/sandbox/expire', token);
    expect(expired.body.plan).to.equal('free');
    const lockedById = Object.fromEntries(
      [...(await jenkins(token)), ...(await github(token))].map((c) => [c._id, c.locked]),
    );
    expect(lockedById).to.deep.equal({ [a._id]: false, [b._id]: true, [g._id]: true });
    expect((await secret(token, 'credentials', a._id)).status).to.equal(200);
    for (const [kind, id] of [['credentials', b._id], ['github-credentials', g._id]]) {
      const res = await secret(token, kind, id);
      expect(res.status, `${kind} secret`).to.equal(403);
      expect(res.body).to.include({ code: 'PLAN_LIMIT', limit: 'locked' });
      expect(JSON.stringify(res.body)).not.to.contain('p-beta').and.not.to.contain('ghp_journey');
    }
    const switched = await authed('post', `/api/credentials/switch/${b._id}`, token);
    expect(switched.status).to.equal(403);
    expect(switched.body).to.include({ limit: 'locked' });
    expect((await addJenkins(token, 'gamma')).status).to.equal(403);

    // Student year: Pro with source student, everything unlocked again.
    await student.grantStudentYear(userId, new Date());
    const asStudent = await plan(token);
    expect(asStudent).to.include({ plan: 'pro', source: 'student' });
    expect((await secret(token, 'credentials', b._id)).body.password).to.equal('p-beta');
    expect((await authed('post', `/api/credentials/switch/${b._id}`, token)).status).to.equal(200);

    // The year ends: Free by the date alone, locked guard back, data kept.
    await student.grantStudentYear(userId, new Date(Date.now() - 366 * DAY));
    expect((await plan(token)).plan).to.equal('free');
    const after = [...(await jenkins(token)), ...(await github(token))];
    expect(after).to.have.length(3);
    expect(after.filter((c) => !c.locked)).to.have.length(1);
  });
});
