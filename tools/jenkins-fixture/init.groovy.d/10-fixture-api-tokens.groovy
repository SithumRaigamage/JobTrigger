// Generates one API token per fixture user on first boot and writes them to
// $JENKINS_HOME/fixture-tokens.properties, which `fixture.sh` copies into the
// git-ignored `.fixture-credentials`. The app is always tested with an API
// token (the recommended credential, US-JX-22), never the account password.
import hudson.model.User
import jenkins.model.Jenkins
import jenkins.security.ApiTokenProperty

def out = new File(Jenkins.get().rootDir, 'fixture-tokens.properties')
if (out.exists()) {
  return
}

def lines = []
['admin', 'viewer'].each { id ->
  def user = User.getById(id, false)
  if (user == null) {
    println "[fixture] user '${id}' not found, no token generated"
    return
  }
  def property = user.getProperty(ApiTokenProperty)
  def token = property.tokenStore.generateNewToken('jobtrigger-fixture')
  user.save()
  lines << "${id}=${token.plainValue}"
}
out.text = lines.join('\n') + '\n'
println "[fixture] API tokens written for: ${lines.collect { it.split('=')[0] }}"
