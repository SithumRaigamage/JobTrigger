const { api } = require('./support/api');
const { expect } = require('chai');
const mongoose = require('mongoose');
const crypto = require('crypto');
const SupportTicket = require('../models/SupportTicket');
const AppInfo = require('../models/AppInfo');
const User = require('../models/User');
const jobs = require('../lib/studentJobs');
const { isEncrypted } = require('../security/secretCipher');
const { setTransportForTests } = require('../lib/mailer');

const PNG = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  Buffer.from('fake png body'),
  crypto.randomBytes(8),
]);
const JPG = Buffer.concat([
  Buffer.from([0xff, 0xd8, 0xff, 0xe0]),
  Buffer.from('fake jpg body'),
  crypto.randomBytes(8),
]);
const PDF = Buffer.from('%PDF-1.4\nnot a screenshot');

let counter = 0;
async function signup(role) {
  counter += 1;
  const email = `support31-${counter}@example.com`;
  const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
  if (role) await User.updateOne({ _id: res.body.user._id }, { $set: { role } });
  return { ...res.body, email };
}

const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);
const valid = {
  category: 'bug',
  subject: 'Console shows nothing',
  message: 'The finished build has a blank console.',
};
const shot = (bytes) => ({ name: 'screenshot.png', data: bytes.toString('base64') });

describe('Support tickets: richer options and screenshots (Phase 31)', function () {
  afterEach(function () {
    setTransportForTests(null);
  });

  it('stores options, encrypts screenshots and never returns bytes to the reporter', async function () {
    const me = await signup();
    const created = await authed('post', '/api/support/tickets', me.token).send({
      ...valid,
      areas: ['jenkins', 'phone'],
      impact: 'blocked',
      screenshots: [shot(PNG), shot(JPG)],
    });
    expect(created.status).to.equal(201);
    expect(created.body.ticket.areas).to.deep.equal(['jenkins', 'phone']);
    expect(created.body.ticket.impact).to.equal('blocked');
    expect(created.body.ticket.screenshotCount).to.equal(2);
    expect(JSON.stringify(created.body)).to.not.include(PNG.toString('base64'));

    const mine = await authed('get', '/api/support/tickets', me.token);
    expect(mine.body.tickets[0].screenshotCount).to.equal(2);
    expect(JSON.stringify(mine.body)).to.not.include(PNG.toString('base64'));

    const raw = await SupportTicket.collection.findOne({ _id: new mongoose.Types.ObjectId(created.body.ticket.id) });
    expect(isEncrypted(raw.screenshots[0].data)).to.equal(true);
    expect(raw.screenshots[0].mime).to.equal('image/png');
    expect(raw.screenshots[0].size).to.equal(PNG.length);
    expect(raw.screenshots[0].hash).to.match(/^[a-f0-9]{64}$/);
    expect(raw.screenshots[0].deleteAt).to.be.instanceOf(Date);

    const admin = await signup('superAdmin');
    const detail = await authed('get', `/api/admin/support/tickets/${created.body.ticket.id}`, admin.token);
    expect(detail.status).to.equal(200);
    expect(detail.body.ticket.screenshots).to.have.length(2);
    expect(detail.body.ticket.screenshots[0]).to.include({ index: 0, mime: 'image/png', size: PNG.length });
    expect(JSON.stringify(detail.body)).to.not.include(PNG.toString('base64'));

    const image = await authed('get', `/api/admin/support/tickets/${created.body.ticket.id}/screenshots/0`, admin.token);
    expect(image.status).to.equal(200);
    expect(image.headers['content-type']).to.include('image/png');
    expect(image.headers['cache-control']).to.equal('no-store');
    expect(Buffer.from(image.body)).to.deep.equal(PNG);

    expect((await authed('get', `/api/admin/support/tickets/${created.body.ticket.id}/screenshots/9`, admin.token)).status).to.equal(404);
    expect((await authed('get', `/api/admin/support/tickets/${created.body.ticket.id}`, me.token)).status).to.equal(404);
    expect((await authed('get', `/api/admin/support/tickets/${created.body.ticket.id}/screenshots/0`, me.token)).status).to.equal(404);
  });

  it('rejects unknown options and bad screenshot files', async function () {
    const me = await signup();
    const cases = [
      [{ ...valid, areas: ['nope'] }, 400],
      [{ ...valid, areas: 'jenkins' }, 400],
      [{ ...valid, impact: 'catastrophic' }, 400],
      [{ ...valid, screenshots: [shot(PNG), shot(PNG), shot(PNG), shot(PNG)] }, 400],
      [{ ...valid, screenshots: [shot(Buffer.concat([PNG, Buffer.alloc(5 * 1024 * 1024)]))] }, 413],
      [{ ...valid, screenshots: [shot(Buffer.from('not an image'))] }, 415],
      [{ ...valid, screenshots: [shot(PDF)] }, 415],
    ];
    for (const [body, status] of cases) {
      const res = await authed('post', '/api/support/tickets', me.token).send(body);
      expect(res.status, JSON.stringify({ areas: body.areas, impact: body.impact })).to.equal(status);
    }
    expect(await SupportTicket.countDocuments({ userId: me.user._id })).to.equal(0);
  });

  it('puts the options, screenshot count and admin link in the owner email', async function () {
    await AppInfo.deleteMany({});
    await AppInfo.create({
      appVersion: '1.1.0',
      buildNumber: '1',
      privacyPolicyUrl: 'https://example.com/p',
      termsOfServiceUrl: 'https://example.com/t',
      supportEmail: 'owner@example.com',
      openSourceLicensesUrl: 'https://example.com/l',
    });
    const sent = [];
    setTransportForTests({ sendMail: async (m) => { sent.push(m); return { messageId: 'x' }; } });

    const me = await signup();
    const created = await authed('post', '/api/support/tickets', me.token).send({
      ...valid,
      areas: ['website'],
      impact: 'minor',
      screenshots: [shot(PNG)],
    });
    expect(created.status).to.equal(201);
    expect(sent).to.have.length(1);
    expect(sent[0].text).to.include('Areas: Website');
    expect(sent[0].text).to.include('Impact: minor');
    expect(sent[0].text).to.include('1 screenshot');
    expect(sent[0].text).to.include(`/admin/support/${created.body.ticket.id}`);
    expect(JSON.stringify(sent[0])).to.not.include(PNG.toString('base64'));
  });

  it('clears screenshot bytes after 30 days but keeps the metadata', async function () {
    const me = await signup();
    const created = await authed('post', '/api/support/tickets', me.token).send({
      ...valid,
      screenshots: [shot(PNG)],
    });
    expect(created.status).to.equal(201);
    const id = created.body.ticket.id;
    const raw = await SupportTicket.collection.findOne({ _id: new mongoose.Types.ObjectId(id) });
    await SupportTicket.collection.updateOne(
      { _id: raw._id },
      { $set: { 'screenshots.0.deleteAt': new Date(Date.now() - 1000) } },
    );

    const cleared = await jobs.purgeSupportScreenshots();
    expect(cleared).to.be.at.least(1);
    const after = await SupportTicket.collection.findOne({ _id: raw._id });
    expect(after.screenshots[0].data).to.equal(null);
    expect(after.screenshots[0].deletedAt).to.be.instanceOf(Date);
    expect(after.screenshots[0].mime).to.equal('image/png');
    expect(after.screenshots[0].hash).to.equal(raw.screenshots[0].hash);

    const admin = await signup('superAdmin');
    const image = await authed('get', `/api/admin/support/tickets/${id}/screenshots/0`, admin.token);
    expect(image.status).to.equal(404);
    expect(await jobs.purgeSupportScreenshots()).to.equal(0);
  });
});
