const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const { expect } = require('chai');
const { api } = require('./support/api');
const User = require('../models/User');
const { verifyToken } = require('../security/tokens');

// NFR-SEC-08 AC7 (bcrypt cost) and AC8 (HS256 only).

let counter = 0;
const nextEmail = () => `harden${Date.now()}${counter++}@example.com`;
const rawUser = (id) => User.collection.findOne({ _id: new mongoose.Types.ObjectId(id) });

describe('Password and token hardening (NFR-SEC-08)', function() {
  it('hashes new passwords at cost 12', async function() {
    const email = nextEmail();
    const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
    expect(User.BCRYPT_COST).to.equal(12);
    expect(bcrypt.getRounds((await rawUser(res.body.user._id)).password)).to.equal(12);
  });

  it('re-hashes an older cost-10 password on the next login, without signing anyone out', async function() {
    const email = nextEmail();
    const res = await api().post('/api/auth/signup').send({ email, password: 'password' });
    const id = res.body.user._id;
    await User.collection.updateOne(
      { _id: new mongoose.Types.ObjectId(id) },
      { $set: { password: await bcrypt.hash('password', 10) } },
    );
    expect(bcrypt.getRounds((await rawUser(id)).password)).to.equal(10);

    const wrong = await api().post('/api/auth/login').send({ email, password: 'wrong-password' });
    expect(wrong.status).to.equal(400);
    expect(bcrypt.getRounds((await rawUser(id)).password)).to.equal(10);

    const login = await api().post('/api/auth/login').send({ email, password: 'password' });
    expect(login.status).to.equal(200);
    const after = await rawUser(id);
    expect(bcrypt.getRounds(after.password)).to.equal(12);
    expect(await bcrypt.compare('password', after.password)).to.equal(true);
    expect(after.tokenVersion ?? 0).to.equal(0);
    // The token issued before the re-hash still works.
    const list = await api().get('/api/credentials').set('x-auth-token', res.body.token);
    expect(list.status).to.equal(200);
  });

  it('accepts HS256 tokens only', function() {
    const claims = { id: new mongoose.Types.ObjectId().toString(), tv: 0, typ: 'access' };
    const good = jwt.sign(claims, process.env.JWT_SECRET, { algorithm: 'HS256' });
    expect(verifyToken(good, 'access')).to.include({ id: claims.id });
    const hs512 = jwt.sign(claims, process.env.JWT_SECRET, { algorithm: 'HS512' });
    expect(verifyToken(hs512, 'access')).to.equal(null);
    const [, body] = good.split('.');
    const none = `${Buffer.from('{"alg":"none","typ":"JWT"}').toString('base64url')}.${body}.`;
    expect(verifyToken(none, 'access')).to.equal(null);
  });
});
