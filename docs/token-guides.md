# Token guides

JobTrigger never asks for your password to a CI tool: each credential is a
token you create and can revoke. This page mirrors the in-app **How do I get
a token?** wizard on the Jenkins, GitHub and SonarQube credential screens.

The backend encrypts every token before storing it. Prefer a token that can
only do what you need, and turn on **Read-only server** in the credential
sheet when you only want to watch builds.

## Jenkins

| | |
|---|---|
| **Where** | `<your Jenkins URL>/me/configure` |
| **Create** | *Add new Token* → give it a name → *Generate* |
| **Use** | Your Jenkins username and the token as the password |
| **Scopes** | Jenkins user tokens inherit your account's permissions |
| **Notes** | A token is revoked from the same page. Use a dedicated account with only the job permissions you want to expose. |

1. Open `<base>/me/configure` while signed in to Jenkins.
2. Under **API Token**, choose *Add new Token*, name it (for example
   `JobTrigger`), and select *Generate*.
3. Copy the token once — Jenkins will not show it again — and paste it into
   the app with your Jenkins username.

## GitHub

| | |
|---|---|
| **Where** | <https://github.com/settings/tokens> |
| **Create** | *Generate new token* → classic, or fine-grained |
| **Classic scopes** | `repo` and `workflow` |
| **Fine-grained** | Repository access to the repositories you watch; **Actions: read and write**, **Contents: read**, **Metadata: read** |
| **Notes** | Fine-grained tokens are per organisation/repository and expire; renew them before they do. Read-only watching only needs Actions and Contents read access. |

1. Open <https://github.com/settings/tokens>.
2. For a classic token, tick `repo` (private repositories and their
   workflows) and `workflow` (dispatch workflows), then generate it.
3. For a fine-grained token, pick the repositories, then grant **Actions:
   read and write**, **Contents: read** and **Metadata: read**.
4. Copy the token and paste it into the app.

## SonarQube

| | |
|---|---|
| **Where** | SonarQube: `<your SonarQube URL>/user/account/security` · SonarCloud: <https://sonarcloud.io/account/security> |
| **Create** | *Generate Tokens* → name it → *Generate* |
| **Use** | The token as the username with an empty password (the app sends it as a bearer token) |
| **Scopes** | User tokens inherit your SonarQube permissions |
| **Notes** | Revoke a token from the same page. A project-scoped token is enough for quality gates, measures and issues. |

1. Open the security page for your SonarQube server or SonarCloud.
2. Under **Tokens**, name a new token (`JobTrigger`) and generate it.
3. Copy it once and paste it into the app; no password is needed.

## Keeping tokens safe

- Revoke a token in the tool when you stop using JobTrigger or lose a device.
- Turn on **Read-only server** for credentials that should never trigger or
  change anything; the app then disables those actions.
- JobTrigger only sends a token to the server URL you saved for it.
