const { api } = require('./support/api');
const { expect } = require('chai');
const JenkinsCredential = require('../models/JenkinsCredential');
const GitHubCredential = require('../models/GitHubCredential');
const SonarQubeCredential = require('../models/SonarQubeCredential');
const releasedTools = require('../lib/releasedTools');
const shipped = require('../config/tools.json');

let counter = 0;
async function signup() {
  counter += 1;
  const res = await api().post('/api/auth/signup').send({ email: `release${counter}@example.com`, password: 'password' });
  return res.body;
}
const authed = (method, path, token) => api()[method](path).set('x-auth-token', token);

const bodies = {
  jenkins: ['/api/credentials', { serverName: 'ci', jenkinsURL: 'https://ci.example.com', username: 'u', password: 'p' }, JenkinsCredential],
  github: ['/api/github-credentials', { label: 'gh', token: 't' }, GitHubCredential],
  sonarqube: ['/api/sonarqube-credentials', { label: 'sq', token: 't' }, SonarQubeCredential],
};

const atRelease = (release) => ({ release, tools: shipped.tools });

describe('Release manifest: which tools can get credentials', function() {
  let restore;
  afterEach(function() {
    if (restore) releasedTools.restore(restore);
    restore = undefined;
  });

  describe('release 1.0 (Jenkins only)', function() {
    beforeEach(function() {
      restore = releasedTools.useManifest(atRelease('1.0'));
    });

    it('still creates Jenkins credentials', async function() {
      const me = await signup();
      const [path, body] = bodies.jenkins;
      const res = await authed('post', path, me.token).send(body);
      expect(res.status).to.equal(201);
    });

    for (const tool of ['github', 'sonarqube']) {
      it(`refuses a ${tool} credential with 403 "not available yet" and saves nothing`, async function() {
        const me = await signup();
        const [path, body, Model] = bodies[tool];
        const res = await authed('post', path, me.token).send(body);
        expect(res.status).to.equal(403);
        expect(res.body.message).to.equal('This tool is not available yet');
        expect(res.body.code).to.equal('TOOL_NOT_AVAILABLE');
        expect(res.body.tool).to.equal(tool);
        expect(await Model.countDocuments({ userId: me.user._id })).to.equal(0);
      });
    }

    it('answers the same whatever the plan, and before validating the body', async function() {
      const me = await signup();
      const res = await authed('post', '/api/github-credentials', me.token).send({});
      expect(res.status).to.equal(403);
      expect(res.body.code).to.equal('TOOL_NOT_AVAILABLE');
    });

    it('needs a signed-in user first', async function() {
      const res = await api().post('/api/github-credentials').send(bodies.github[1]);
      expect(res.status).to.equal(401);
    });

    it('leaves what is already saved alone: list, update and delete still work', async function() {
      const me = await signup();
      releasedTools.restore(restore);
      restore = releasedTools.useManifest(releasedTools.allToolsManifest());
      const created = await authed('post', bodies.github[0], me.token).send(bodies.github[1]);
      expect(created.status).to.equal(201);

      releasedTools.restore(restore);
      restore = releasedTools.useManifest(atRelease('1.0'));
      const path = `/api/github-credentials/${created.body._id}`;
      const list = await authed('get', '/api/github-credentials', me.token);
      expect(list.status).to.equal(200);
      expect(list.body).to.have.length(1);
      expect((await authed('put', path, me.token).send({ label: 'renamed' })).status).to.equal(200);
      expect((await authed('delete', path, me.token)).status).to.equal(200);
    });
  });

  it('release 1.1 opens SonarQube but not GitHub; 1.2 opens GitHub', async function() {
    const me = await signup();
    restore = releasedTools.useManifest(atRelease('1.1'));
    expect((await authed('post', bodies.sonarqube[0], me.token).send(bodies.sonarqube[1])).status).to.equal(201);
    expect((await authed('post', bodies.github[0], me.token).send(bodies.github[1])).status).to.equal(403);
    releasedTools.useManifest(atRelease('1.2'));
    // GitHub is released now, so the gate lets it through. What happens next
    // is the plan's business (a Free user already has one server), so only
    // the gate's own answer is asserted.
    const res = await authed('post', bodies.github[0], me.token).send(bodies.github[1]);
    expect(res.body.code).to.not.equal('TOOL_NOT_AVAILABLE');
  });
});

describe('Release manifest ids map to this backend\'s tools', function() {
  it('every tool in the shipped manifest maps to a local tool or is planned only', function() {
    for (const id of Object.keys(shipped.tools)) {
      const known = id in releasedTools.LOCAL_TOOL || releasedTools.PLANNED_ONLY.includes(id);
      expect(known, id).to.equal(true);
    }
  });

  it('"githubActions" is this backend\'s "github"; nothing else is renamed', function() {
    expect(releasedTools.LOCAL_TOOL).to.deep.equal({ jenkins: 'jenkins', githubActions: 'github', sonarqube: 'sonarqube' });
  });

  it('the all-tools test manifest releases every local tool and nothing planned', function() {
    const all = releasedTools.releasedLocalTools(releasedTools.allToolsManifest());
    expect([...all].sort()).to.deep.equal(['github', 'jenkins', 'sonarqube']);
  });

  it('the shipped manifest releases Jenkins only', function() {
    expect([...releasedTools.releasedLocalTools(shipped)]).to.deep.equal(['jenkins']);
  });

  it('versions compare as numbers: 1.10 is after 1.2', function() {
    const set = releasedTools.releasedLocalTools({ release: '1.2', tools: { jenkins: '1.0', sonarqube: '1.10' } });
    expect([...set]).to.deep.equal(['jenkins']);
  });

  it('an unknown tool id fails loudly', function() {
    expect(() => releasedTools.releasedLocalTools({ release: '1.0', tools: { jenkins: '1.0', gitea: '1.1' } }))
      .to.throw('Unknown tool "gitea"');
  });

  it('a released tool with no code, a bad version or a bad manifest fails loudly', function() {
    expect(() => releasedTools.releasedLocalTools({ release: '1.3', tools: { jenkins: '1.0', gitlab: '1.3' } }))
      .to.throw('released but has no code');
    expect(() => releasedTools.releasedLocalTools({ release: '1.0', tools: { jenkins: 'one' } })).to.throw('bad version');
    expect(() => releasedTools.releasedLocalTools(null)).to.throw('not a release manifest');
  });
});
