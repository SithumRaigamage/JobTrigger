import '../../domain/auth/user.dart';
import '../../domain/credential/github_credential.dart';
import '../../domain/credential/jenkins_server.dart';
import '../../domain/credential/sonarqube_credential.dart';

/// E2: fixed identities for demo mode. None of this is a real account or
/// server. The `.invalid` top-level domain is reserved (RFC 2606) and never
/// resolves, and the secrets are empty placeholders: nothing here can reach
/// a network or open a real session.
const demoJenkinsBaseUrl = 'https://jenkins.demo.invalid/';
const demoSonarQubeBaseUrl = 'https://sonarqube.demo.invalid';

const demoUser = User(id: 'demo-user', email: 'demo@jobtrigger.app');

const demoJenkinsServer = JenkinsServer(
  id: 'demo-jenkins',
  serverName: 'Demo Jenkins',
  jenkinsURL: demoJenkinsBaseUrl,
  username: 'demo',
  secret: 'demo-not-a-secret',
  isDefault: true,
);

const demoGitHubCredential = GitHubCredential(
  id: 'demo-github',
  label: 'Demo GitHub',
  secret: 'demo-not-a-secret',
  defaultOwner: 'demo-org',
  isDefault: true,
);

const demoSonarQubeCredential = SonarQubeCredential(
  id: 'demo-sonarqube',
  label: 'Demo SonarQube',
  baseUrl: demoSonarQubeBaseUrl,
  secret: 'demo-not-a-secret',
  isDefault: true,
);
