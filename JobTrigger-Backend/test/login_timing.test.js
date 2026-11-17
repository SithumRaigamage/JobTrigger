const { api } = require('./support/api');
const { expect } = require('chai');
const bcrypt = require('bcrypt');

// AUD-55: an unknown email must cost the same bcrypt work as a wrong
// password, so response time can't be used to find registered emails.
describe('Login without an account (AUD-55)', function() {
  it('still runs a bcrypt comparison before refusing', async function() {
    const original = bcrypt.compare;
    let compares = 0;
    bcrypt.compare = (...args) => {
      compares += 1;
      return original.apply(bcrypt, args);
    };
    try {
      const res = await api()
        .post('/api/auth/login')
        .send({ email: 'nobody-here@example.com', password: 'whatever-1' });
      expect(res.status).to.equal(400);
      expect(res.body.message).to.equal('Invalid credentials');
    } finally {
      bcrypt.compare = original;
    }
    expect(compares).to.equal(1);
  });
});
