const request = require('supertest');
const { expect } = require('chai');
const { app } = require('../server');

describe('Credential id validation', function() {
  let token;

  before(async function() {
    const signupRes = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'idvalidation@example.com', password: 'password' });
    token = signupRes.body.token;
  });

  const validMissingId = '507f1f77bcf86cd799439011'; // well-formed ObjectId, no such document

  describe('Jenkins credentials', function() {
    it('should return 400 for a malformed id on update', async function() {
      const res = await request(app)
        .put('/api/credentials/not-an-object-id')
        .set('x-auth-token', token)
        .send({ serverName: 'X', jenkinsURL: 'http://x', username: 'u', password: 'p' });
      expect(res.status).to.equal(400);
    });

    it('should return 400 for a malformed id on delete', async function() {
      const res = await request(app)
        .delete('/api/credentials/not-an-object-id')
        .set('x-auth-token', token);
      expect(res.status).to.equal(400);
    });

    it('should return 400 for a malformed id on switch', async function() {
      const res = await request(app)
        .post('/api/credentials/switch/not-an-object-id')
        .set('x-auth-token', token);
      expect(res.status).to.equal(400);
    });

    it('should return 404 for a well-formed but missing id on update', async function() {
      const res = await request(app)
        .put(`/api/credentials/${validMissingId}`)
        .set('x-auth-token', token)
        .send({ serverName: 'X', jenkinsURL: 'http://x', username: 'u', password: 'p' });
      expect(res.status).to.equal(404);
    });

    it('should return 404 for a well-formed but missing id on delete', async function() {
      const res = await request(app)
        .delete(`/api/credentials/${validMissingId}`)
        .set('x-auth-token', token);
      expect(res.status).to.equal(404);
    });

    it('should return 404 for a well-formed but missing id on switch', async function() {
      const res = await request(app)
        .post(`/api/credentials/switch/${validMissingId}`)
        .set('x-auth-token', token);
      expect(res.status).to.equal(404);
    });

    it('should return 400 when adding a credential with a missing required field', async function() {
      const res = await request(app)
        .post('/api/credentials')
        .set('x-auth-token', token)
        .send({ jenkinsURL: 'http://x', username: 'u', password: 'p' }); // no serverName
      expect(res.status).to.equal(400);
    });
  });

  describe('GitHub credentials', function() {
    it('should return 400 for a malformed id on update', async function() {
      const res = await request(app)
        .put('/api/github-credentials/not-an-object-id')
        .set('x-auth-token', token)
        .send({ label: 'X', token: 'ghp_x' });
      expect(res.status).to.equal(400);
    });

    it('should return 400 for a malformed id on delete', async function() {
      const res = await request(app)
        .delete('/api/github-credentials/not-an-object-id')
        .set('x-auth-token', token);
      expect(res.status).to.equal(400);
    });

    it('should return 400 for a malformed id on switch', async function() {
      const res = await request(app)
        .post('/api/github-credentials/switch/not-an-object-id')
        .set('x-auth-token', token);
      expect(res.status).to.equal(400);
    });

    it('should return 404 for a well-formed but missing id on update', async function() {
      const res = await request(app)
        .put(`/api/github-credentials/${validMissingId}`)
        .set('x-auth-token', token)
        .send({ label: 'X', token: 'ghp_x' });
      expect(res.status).to.equal(404);
    });

    it('should return 404 for a well-formed but missing id on delete', async function() {
      const res = await request(app)
        .delete(`/api/github-credentials/${validMissingId}`)
        .set('x-auth-token', token);
      expect(res.status).to.equal(404);
    });

    it('should return 404 for a well-formed but missing id on switch', async function() {
      const res = await request(app)
        .post(`/api/github-credentials/switch/${validMissingId}`)
        .set('x-auth-token', token);
      expect(res.status).to.equal(404);
    });

    it('should return 400 when adding a credential with a missing required field', async function() {
      const res = await request(app)
        .post('/api/github-credentials')
        .set('x-auth-token', token)
        .send({ defaultOwner: 'octocat' }); // no label, no token
      expect(res.status).to.equal(400);
    });
  });

  describe('SonarQube credentials', function() {
    it('should return 400 for a malformed id on update', async function() {
      const res = await request(app)
        .put('/api/sonarqube-credentials/not-an-object-id')
        .set('x-auth-token', token)
        .send({ label: 'X', baseUrl: 'https://sonarcloud.io', token: 'squ_x' });
      expect(res.status).to.equal(400);
    });

    it('should return 400 for a malformed id on delete', async function() {
      const res = await request(app)
        .delete('/api/sonarqube-credentials/not-an-object-id')
        .set('x-auth-token', token);
      expect(res.status).to.equal(400);
    });

    it('should return 400 for a malformed id on switch', async function() {
      const res = await request(app)
        .post('/api/sonarqube-credentials/switch/not-an-object-id')
        .set('x-auth-token', token);
      expect(res.status).to.equal(400);
    });

    it('should return 404 for a well-formed but missing id on update', async function() {
      const res = await request(app)
        .put(`/api/sonarqube-credentials/${validMissingId}`)
        .set('x-auth-token', token)
        .send({ label: 'X', baseUrl: 'https://sonarcloud.io', token: 'squ_x' });
      expect(res.status).to.equal(404);
    });

    it('should return 404 for a well-formed but missing id on delete', async function() {
      const res = await request(app)
        .delete(`/api/sonarqube-credentials/${validMissingId}`)
        .set('x-auth-token', token);
      expect(res.status).to.equal(404);
    });

    it('should return 404 for a well-formed but missing id on switch', async function() {
      const res = await request(app)
        .post(`/api/sonarqube-credentials/switch/${validMissingId}`)
        .set('x-auth-token', token);
      expect(res.status).to.equal(404);
    });

    it('should return 400 when adding a credential with a missing required field', async function() {
      const res = await request(app)
        .post('/api/sonarqube-credentials')
        .set('x-auth-token', token)
        .send({ defaultOrganization: 'octocat-org' }); // no label, no baseUrl, no token
      expect(res.status).to.equal(400);
    });
  });
});
