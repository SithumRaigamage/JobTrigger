# Fixture Jenkins for JobTrigger's real-server verification (NFR-TEST-02,
# tasks/phase-11-jenkins-extended.md P11-01). Local development only — never
# deploy this image anywhere reachable: it's a throwaway server whose whole
# point is to be driven by tests.
FROM jenkins/jenkins:2.568.3-lts-jdk21

# No setup wizard: users, security, and jobs all come from casc.yaml.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false \
  -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc.yaml

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# A local git repo for the multibranch fixture (US-JX-03): branches `main`
# and `feature/login` (so the app sees `feature%2Flogin`), plus tag `v1.0.0`.
USER root
COPY sample-repo/ /tmp/sample-repo/
RUN git config --global init.defaultBranch main \
  && git config --global user.email fixture@jobtrigger.local \
  && git config --global user.name "Fixture Bot" \
  && git init --bare /srv/repos/sample.git \
  && cd /tmp/sample-repo && git init && git add . && git commit -qm "Initial pipeline" \
  && git tag v1.0.0 \
  && git checkout -qb feature/login \
  && sed -i 's/FIXTURE_BRANCH_FAILS=false/FIXTURE_BRANCH_FAILS=true/' Jenkinsfile \
  && git commit -qam "Feature branch that fails its test stage" \
  && git remote add origin /srv/repos/sample.git \
  && git push -q origin main feature/login --tags \
  && chown -R jenkins:jenkins /srv/repos \
  && rm -rf /tmp/sample-repo
USER jenkins

COPY casc.yaml /usr/share/jenkins/ref/casc.yaml
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
