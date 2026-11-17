# Token guides

JobTrigger never asks for an account password. Every tool it connects to
accepts a revocable token, and revoking one does not change anything else
about your account. The app's credential sheets each have a **How do I get a
token?** button that opens the same short guide, with a link straight to the
right page.

Only a token's creation page is linked — JobTrigger never asks you to paste a
token into a website, and the app stores it encrypting at rest.

## Jenkins

1. Open `<your Jenkins URL>/me/configure` (the app links it for you; every
   supported Jenkins version redirects to the right place).
2. Under **API Token**, choose **Add new Token**, name it `JobTrigger`, and
   generate it.
3. Copy the token — Jenkins shows it once — and paste it as the API token in
   JobTrigger, together with your Jenkins username.

Scope: a normal user token inherits your own permissions. There is nothing
extra to tick.

The app warns when the secret you typed looks like an account password
instead of a token; a token is still accepted either way, but it is safer.

## GitHub

Classic token (`ghp_…`):

1. Open <https://github.com/settings/tokens/new> (pre-filled with the scopes
   below).
2. Tick **repo** — private repositories, commits and workflow files.
3. Tick **workflow** — lets JobTrigger start a workflow run.
4. Generate, copy, and paste it as the personal access token.

Fine-grained token (`github_pat_…`): choose the repositories JobTrigger may
see, then grant **Actions: read and write** (to run and read workflows) and
**Contents: read** (to read workflow files).

If you only work with public repositories, a token with public-repo access is
enough; the app does not need anything else.

## SonarQube

1. Open your account security page:
   - SonarCloud: <https://sonarcloud.io/account/security>
   - Self-hosted or SonarQube Server: `<your SonarQube URL>/user/account/security`
     (the app links your instance).
2. Choose **Generate token**, give it a name, and generate it.
3. Copy the token — it is shown once — and paste it as the user token.

For SonarCloud, also fill in your organization key; a self-hosted server
leaves it blank.

## What the app stores

Tokens and passwords are encrypted before they leave the device and are
never written to logs, analytics or crash reports. Removing a credential in
**Settings** forgets it locally; revoke the token at the tool as well if you
want it to stop working everywhere.
