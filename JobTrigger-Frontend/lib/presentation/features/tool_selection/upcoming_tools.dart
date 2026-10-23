/// Tools shown under "Coming later" on the tool-selection screen: listed so
/// users can see what's planned, never selectable. Display data only — a
/// tool joins [CiTool] (and gets credentials, a client and screens) when
/// its epic is built; see `tasks/backlog.md`'s "Coming-later tools".
///
/// Only tools with a remote API are listed: a phone can't run a CLI, so
/// Terraform, Ansible and the like appear as their hosted or server form.
class UpcomingToolGroup {
  const UpcomingToolGroup(this.name, this.tools);

  final String name;
  final List<String> tools;
}

const upcomingToolGroups = [
  UpcomingToolGroup('CI and build', [
    'GitLab CI',
    'CircleCI',
    'Azure DevOps Pipelines',
    'Bitbucket Pipelines',
    'TeamCity',
    'Bamboo',
    'Travis CI',
    'Buildkite',
    'Drone / Harness CI',
    'Woodpecker CI',
    'Concourse',
    'GoCD',
    'Semaphore',
    'Codefresh',
    'AWS CodeBuild / CodePipeline',
    'Google Cloud Build',
    'Gitea / Forgejo Actions',
    'Tekton',
  ]),
  UpcomingToolGroup('Deployment and GitOps', [
    'Argo CD',
    'Argo Workflows / Rollouts',
    'Flux',
    'Spinnaker',
    'Harness CD',
    'Octopus Deploy',
    'AWS CodeDeploy',
  ]),
  UpcomingToolGroup('Infrastructure as code', [
    'HCP Terraform',
    'Pulumi Cloud',
    'Spacelift',
    'env0',
    'Scalr',
    'Atlantis',
  ]),
  UpcomingToolGroup('Configuration and automation', [
    'Ansible AWX / Automation Platform',
    'Rundeck',
    'Puppet Enterprise',
    'Chef Automate',
    'Salt',
  ]),
  UpcomingToolGroup('Containers and orchestration', [
    'Kubernetes',
    'OpenShift',
    'Rancher',
    'Nomad',
    'Portainer',
    'AWS ECS',
  ]),
  UpcomingToolGroup('Code quality and security', [
    'SonarQube',
    'Snyk',
    'Codecov',
    'Coveralls',
    'Checkmarx',
    'Veracode',
    'GitGuardian',
    'Dependabot',
  ]),
  UpcomingToolGroup('Artifacts and registries', [
    'JFrog Artifactory',
    'Sonatype Nexus',
    'Harbor',
    'Docker Hub',
    'GitHub Container Registry',
  ]),
  UpcomingToolGroup('Mobile CI and release', [
    'Bitrise',
    'Codemagic',
    'Xcode Cloud',
    'App Store Connect',
    'Google Play Console',
    'Firebase App Distribution',
  ]),
  UpcomingToolGroup('Monitoring and incidents', [
    'Datadog',
    'Grafana',
    'Prometheus / Alertmanager',
    'PagerDuty',
    'Sentry',
  ]),
];
