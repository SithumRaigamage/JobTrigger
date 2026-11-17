/*
 * What the portal knows about a saved server or account. Plain data for
 * rendering: secrets only ever appear masked (domain/mask.ts). The backend's
 * own shapes, which carry the full secrets, stay inside src/server/.
 */

export type Tool = "jenkins" | "github" | "sonarqube";

type CredentialBase = {
  id: string;
  /** The tool's default ("active") credential, used by the app first. */
  isDefault: boolean;
  /**
   * The backend couldn't decrypt the stored secret (AUD-63): the user has
   * to paste it again. `secretMask` is null then.
   */
  needsReentry: boolean;
  /** "••••" + last 4, or null when the secret is unreadable. */
  secretMask: string | null;
};

export type JenkinsServer = CredentialBase & {
  tool: "jenkins";
  name: string;
  url: string;
  username: string;
  /** Whether an optional build-trigger token is saved (never shown). */
  hasParamToken: boolean;
};

export type GitHubAccount = CredentialBase & {
  tool: "github";
  label: string;
  /** Optional org/user that filters the repository list. */
  defaultOwner: string;
};

export type SonarQubeServer = CredentialBase & {
  tool: "sonarqube";
  label: string;
  baseUrl: string;
  /** Needed for SonarCloud; empty for self-hosted servers. */
  defaultOrganization: string;
};

export type Credential = JenkinsServer | GitHubAccount | SonarQubeServer;

/** The signed-in user, as far as the portal needs to know. */
export type Account = { email: string };
